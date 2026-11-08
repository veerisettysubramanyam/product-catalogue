export interface EmailMessage {
  to: string;
  replyTo?: string;
  subject: string;
  text: string;
}

/**
 * Provider-agnostic email port. Switching to SES, SendGrid, Postmark etc. means
 * adding one implementation and choosing it in server.ts.
 */
export interface EmailSender {
  send(message: EmailMessage): Promise<void>;
}
