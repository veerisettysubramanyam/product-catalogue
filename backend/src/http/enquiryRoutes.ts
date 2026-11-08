import { Router } from "express";
import { rateLimit } from "express-rate-limit";

import { enquirySchema, type EnquiryService } from "../enquiries/enquiryService.js";

export function enquiryRoutes(enquiries: EnquiryService, options: { ratePerMinute: number }): Router {
  const router = Router();

  // Simple per-IP limit to stop the form being used to spam the sales inbox.
  const limiter = rateLimit({
    windowMs: 60_000,
    limit: options.ratePerMinute,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    handler: (_req, res) => {
      res.status(429).json({
        error: { code: "rate_limited", message: "Too many enquiries. Please try again in a minute." },
      });
    },
  });

  router.post("/enquiries", limiter, async (req, res) => {
    const input = enquirySchema.parse(req.body ?? {});
    const receipt = await enquiries.submit(input);
    res.status(201).json(receipt);
  });

  return router;
}
