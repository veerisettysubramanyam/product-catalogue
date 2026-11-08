import cors from "cors";
import express from "express";
import helmet from "helmet";

import { errorHandler, notFoundHandler } from "./http/errors.js";

export interface AppOptions {
  corsOrigin: string;
}

/**
 * Builds the HTTP app from injected dependencies so tests can swap in fakes
 * and production can swap data sources or email providers without touching routes.
 */
export function createApp(options: AppOptions) {
  const app = express();

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(cors({ origin: options.corsOrigin }));
  app.use(express.json({ limit: "10kb" }));

  app.get("/health", (_req, res) => {
    res.json({ status: "ok" });
  });

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
