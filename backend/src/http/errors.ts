import type { ErrorRequestHandler, RequestHandler } from "express";
import { ZodError } from "zod";

export class AppError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = new.target.name;
  }
}

export class NotFoundError extends AppError {
  constructor(message = "Resource not found") {
    super(404, "not_found", message);
  }
}

/** The product data source failed or timed out. Callers see a generic 502. */
export class UpstreamError extends AppError {
  constructor(message = "Product data is temporarily unavailable", options?: { cause?: unknown }) {
    super(502, "upstream_unavailable", message);
    if (options?.cause) this.cause = options.cause;
  }
}

export class EmailDeliveryError extends AppError {
  constructor(options?: { cause?: unknown }) {
    super(502, "email_failed", "We couldn't send your enquiry. Please try again shortly.");
    if (options?.cause) this.cause = options.cause;
  }
}

export const notFoundHandler: RequestHandler = (_req, _res, next) => {
  next(new NotFoundError("Route not found"));
};

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof ZodError) {
    res.status(400).json({
      error: {
        code: "validation_failed",
        message: "Request is invalid",
        details: err.issues.map((issue) => ({ field: issue.path.join("."), message: issue.message })),
      },
    });
    return;
  }

  // Malformed JSON body from express.json()
  if (isBodyParserError(err)) {
    res.status(err.status).json({ error: { code: "bad_request", message: "Malformed request body" } });
    return;
  }

  if (err instanceof AppError) {
    if (err.status >= 500) console.error(`[${err.code}]`, err.message, err.cause ?? "");
    res.status(err.status).json({
      error: { code: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) },
    });
    return;
  }

  console.error("Unhandled error", err);
  res.status(500).json({ error: { code: "internal_error", message: "Something went wrong" } });
};

function isBodyParserError(err: unknown): err is { status: number; type: string } {
  return (
    typeof err === "object" &&
    err !== null &&
    "type" in err &&
    "status" in err &&
    typeof (err as { status: unknown }).status === "number" &&
    (err as { status: number }).status < 500
  );
}
