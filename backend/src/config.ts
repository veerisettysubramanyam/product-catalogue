import { z } from "zod";

const booleanFromEnv = z
  .enum(["true", "false"])
  .default("false")
  .transform((value) => value === "true");

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  CORS_ORIGIN: z.string().default("*"),

  FAKE_STORE_BASE_URL: z.url().default("https://fakestoreapi.com"),
  FAKE_STORE_TIMEOUT_MS: z.coerce.number().int().positive().default(5000),
  PRODUCT_CACHE_TTL_SECONDS: z.coerce.number().int().nonnegative().default(300),
  CURATION_FILE: z.string().default("config/curation.json"),

  // "smtp" sends real mail (Mailpit locally); "console" just logs it.
  EMAIL_TRANSPORT: z.enum(["smtp", "console"]).default("console"),
  SALES_INBOX: z.email().default("sales@example.com"),
  EMAIL_FROM: z.email().default("catalogue@example.com"),
  SMTP_HOST: z.string().default("localhost"),
  SMTP_PORT: z.coerce.number().int().positive().default(1025),
  SMTP_SECURE: booleanFromEnv,
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),

  ENQUIRY_RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(5),
});

export type Config = z.infer<typeof envSchema>;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const result = envSchema.safeParse(env);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Invalid configuration: ${problems}`);
  }
  return result.data;
}
