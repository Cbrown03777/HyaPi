// apps/api/src/gov/boost.ts
export const GOV_BOOST = Object.freeze({
  26: 0.20,
  52: 0.35,
  104: 0.50,
} as const);

export type { LockTermWeeks } from './types';
import type { UserLock, LockTermWeeks } from './types';

export interface BoostInfo {
  boostPct: number;       // 0..1
  active: boolean;
  termWeeks?: LockTermWeeks;
  unlockAt?: string;
}

import { getUserLock } from '../data/govRepo';

export async function getBoostForUser(userId: string): Promise<BoostInfo> {
  const lock = await getUserLock(userId);
  if (!lock) return { boostPct: 0, active: false };
  const now = Date.now();
  const unlock = new Date(lock.unlockAt).getTime();
  const active = unlock > now;
  const boostPct = active ? (GOV_BOOST[lock.termWeeks as 26|52|104] ?? 0) : 0;
  return { boostPct, active, termWeeks: lock.termWeeks as 26|52|104, unlockAt: lock.unlockAt };
}
