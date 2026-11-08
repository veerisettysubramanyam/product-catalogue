import request from "supertest";
import { describe, expect, it } from "vitest";

import { makeTestApp, RecordingEmailSender, SALES_INBOX } from "./support/fakes.js";

const validEnquiry = {
  productId: "4",
  name: "Asha Rao",
  email: "asha@example.com",
  phone: "+91 98765 43210",
  message: "Do you ship to Bengaluru?",
};

function setup(options: { enquiryRateLimitPerMinute?: number } = {}) {
  const email = new RecordingEmailSender();
  const app = makeTestApp({ email, ...options });
  return { app, email };
}

describe("POST /api/enquiries", () => {
  it("emails the sales inbox and returns a reference", async () => {
    const { app, email } = setup();

    const res = await request(app).post("/api/enquiries").send(validEnquiry);

    expect(res.status).toBe(201);
    expect(res.body.reference).toMatch(/^[0-9a-f-]{36}$/);
    expect(email.sent).toHaveLength(1);
    const [sent] = email.sent;
    expect(sent).toMatchObject({
      to: SALES_INBOX,
      replyTo: "asha@example.com",
      subject: "New enquiry: Gaming Drive",
    });
    expect(sent?.text).toContain("Asha Rao");
    expect(sent?.text).toContain("Do you ship to Bengaluru?");
    expect(sent?.text).toContain(res.body.reference);
  });

  it("accepts an enquiry without phone or message", async () => {
    const { app, email } = setup();
    const res = await request(app)
      .post("/api/enquiries")
      .send({ productId: "4", name: "Asha", email: "asha@example.com" });
    expect(res.status).toBe(201);
    expect(email.sent[0]?.text).toContain("Phone: not provided");
  });

  it.each([
    ["missing name", { ...validEnquiry, name: "   " }, "name"],
    ["invalid email", { ...validEnquiry, email: "not-an-email" }, "email"],
    ["invalid phone", { ...validEnquiry, phone: "call me" }, "phone"],
    ["message too long", { ...validEnquiry, message: "x".repeat(2001) }, "message"],
    ["header injection in name", { ...validEnquiry, name: "Asha\r\nBcc: victim@example.com" }, "name"],
    ["missing productId", { ...validEnquiry, productId: undefined }, "productId"],
  ])("rejects %s with a field error and sends nothing", async (_label, body, field) => {
    const { app, email } = setup();

    const res = await request(app).post("/api/enquiries").send(body);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation_failed");
    expect(res.body.error.details.map((d: { field: string }) => d.field)).toContain(field);
    expect(email.sent).toHaveLength(0);
  });

  it("rejects malformed JSON", async () => {
    const { app } = setup();
    const res = await request(app)
      .post("/api/enquiries")
      .set("Content-Type", "application/json")
      .send("{not json");
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("bad_request");
  });

  it("404s for a product that doesn't exist and sends nothing", async () => {
    const { app, email } = setup();
    const res = await request(app).post("/api/enquiries").send({ ...validEnquiry, productId: "999" });
    expect(res.status).toBe(404);
    expect(email.sent).toHaveLength(0);
  });

  it("returns 502 when the email provider fails", async () => {
    const { app, email } = setup();
    email.failWith = new Error("SMTP connection refused");

    const res = await request(app).post("/api/enquiries").send(validEnquiry);

    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe("email_failed");
    expect(JSON.stringify(res.body)).not.toContain("SMTP");
  });

  it("rate limits repeated submissions", async () => {
    const { app } = setup({ enquiryRateLimitPerMinute: 2 });

    await request(app).post("/api/enquiries").send(validEnquiry).expect(201);
    await request(app).post("/api/enquiries").send(validEnquiry).expect(201);
    const res = await request(app).post("/api/enquiries").send(validEnquiry);

    expect(res.status).toBe(429);
    expect(res.body.error.code).toBe("rate_limited");
  });
});
