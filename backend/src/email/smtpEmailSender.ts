import nodemailer, { type Transporter } from "nodemailer";

import type { EmailMessage, EmailSender } from "./emailSender.js";

export interface SmtpOptions {
  host: string;
  port: number;
  secure: boolean;
  user?: string;
  pass?: string;
  from: string;
}

/** Plain SMTP. Locally this points at Mailpit; in AWS it can point at SES's SMTP endpoint. */
export class SmtpEmailSender implements EmailSender {
  private readonly transporter: Transporter;

  constructor(private readonly options: SmtpOptions) {
    this.transporter = nodemailer.createTransport({
      host: options.host,
      port: options.port,
      secure: options.secure,
      auth: options.user && options.pass ? { user: options.user, pass: options.pass } : undefined,
      connectionTimeout: 10_000,
    });
  }

  async send(message: EmailMessage): Promise<void> {
    await this.transporter.sendMail({ from: this.options.from, ...message });
  }
}
