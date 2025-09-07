import { Router } from 'express';

export const metadataRouter = Router();

metadataRouter.get('/legal', (_req, res) => {
  res.json({ success: true, data: {
    privacy_last_updated: 'Sep 2025',
    terms_last_updated: 'Sep 2025',
  }});
});
