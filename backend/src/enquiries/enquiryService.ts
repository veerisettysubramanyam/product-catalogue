import { randomUUID } from "node:crypto";

import { z } from "zod";

import type { CatalogueService } from "../catalogue/catalogueService.js";
import type { EmailSender } from "../email/emailSender.js";
import { EmailDeliveryError } from "../http/errors.js";

// Control characters (incl. CR/LF) are rejected in single-line fields to rule out header injection.
const singleLine = (max: number) =>
  z
    .string()
    .trim()
    .max(max)
    .refine((value) => !/[\u0000-\u001f\u007f]/.test(value), "Must not contain control characters");

export const enquirySchema = z.object({
  productId: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/, "Invalid product id"),
  name: singleLine(100).pipe(z.string().min(1, "Name is required")),
  email: z.string().trim().max(254).pipe(z.email("Enter a valid email address")),
  phone: singleLine(30)
    .refine((value) => value === "" || /^[0-9+()\-.\s]{6,30}$/.test(value), "Enter a valid phone number")
    .optional(),
  message: z.string().trim().max(2000, "Message is too long").optional(),
});

export type EnquiryInput = z.infer<typeof enquirySchema>;

export interface EnquiryReceipt {
  reference: string;
}

export class EnquiryService {
  constructor(
    private readonly catalogue: CatalogueService,
    private readonly email: EmailSender,
    private readonly salesInbox: string,
  ) {}

  async submit(input: EnquiryInput): Promise<EnquiryReceipt> {
    // Throws NotFoundError for unknown products, so we never email about something that doesn't exist.
    const product = await this.catalogue.getProduct(input.productId);
    const reference = randomUUID();

    const text = [
      `New product enquiry (ref ${reference})`,
      "",
      `Product: ${product.title} (id ${product.id})`,
      `Price: ${product.price.amount.toFixed(2)} ${product.price.currency}`,
      "",
      `Name: ${input.name}`,
      `Email: ${input.email}`,
      `Phone: ${input.phone || "not provided"}`,
      "",
      "Message:",
      input.message || "(no message)",
    ].join("\n");

    try {
      await this.email.send({
        to: this.salesInbox,
        replyTo: input.email,
        subject: `New enquiry: ${product.title}`.replace(/[\r\n]+/g, " ").slice(0, 200),
        text,
      });
    } catch (error) {
      throw new EmailDeliveryError({ cause: error });
    }

    return { reference };
  }
}
