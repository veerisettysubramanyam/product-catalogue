import type { EmailMessage, EmailSender } from "./emailSender.js";

/** Dev fallback when no SMTP server is running: prints the email instead of sending it. */
export class ConsoleEmailSender implements EmailSender {
  async send(message: EmailMessage): Promise<void> {
    console.log(
      ["--- email (console transport) ---", `To: ${message.to}`, `Reply-To: ${message.replyTo ?? "-"}`, `Subject: ${message.subject}`, "", message.text, "---"].join("\n"),
    );
  }
}
