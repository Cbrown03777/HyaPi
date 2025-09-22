// apps/api/src/gov/types.ts

// Lock terms supported for governance boosts
export type LockTermWeeks = 26 | 52 | 104;

// Stored representation of a user's governance lock
export interface UserLock {
  userId: string;         // Pi user identifier (internal numeric id as string)
  termWeeks: LockTermWeeks;
  lockedAt: string;       // ISO timestamp
  unlockAt: string;       // ISO timestamp
  txUrl?: string | null;
}
