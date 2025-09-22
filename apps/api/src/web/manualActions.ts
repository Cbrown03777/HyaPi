import { Router, Request, Response } from 'express';
import { z } from 'zod';
import * as repo from '../data/actionsRepo';
import { confirmPlannedAction } from '../services/manualConversion';

export const manualActionsRouter = Router();

const CreateSchema = z.object({ venue: z.string().min(1), amountPI: z.number().positive(), note: z.string().optional() });

manualActionsRouter.get('/actions', async (req: Request, res: Response) => {
  try {
    const status = (req.query.status as string | undefined);
    const filter = status && (status === 'Planned' || status === 'Confirmed') ? status : undefined;
    const rows = await repo.listActions(filter);
    res.json({ success: true, data: rows });
  } catch (e:any) {
    const s = e.status || 500;
    res.status(s).json({ success:false, error:{ code: e.code || 'SERVER', message: e.message || 'list failed' }});
  }
});

manualActionsRouter.post('/actions', async (req: Request, res: Response) => {
  try {
    const parsed = CreateSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ success:false, error:{ code:'INVALID_INPUT', message:'venue and amountPI required' }});
    const { venue, amountPI, note } = parsed.data;
    const row = await repo.createPlannedAction(venue, amountPI, note);
    res.json({ success:true, data: row });
  } catch (e:any) {
    const s = e.status || 500;
    res.status(s).json({ success:false, error:{ code: e.code || 'SERVER', message: e.message || 'create failed' }});
  }
});

manualActionsRouter.post('/actions/:id/confirm', async (req: Request, res: Response) => {
  try {
    const id = req.params.id;
    const out = await confirmPlannedAction(id, req.body || {});
    res.json({ success:true, data: out });
  } catch (e:any) {
    const s = e.status || 500;
    res.status(s).json({ success:false, error:{ code: e.code || 'SERVER', message: e.message || 'confirm failed' }});
  }
});
