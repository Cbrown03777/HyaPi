const mem = new Map<string, { value:any; exp:number }>();
export async function getCache(key:string){ const v = mem.get(key); if(!v) return null; if(Date.now()>v.exp){ mem.delete(key); return null;} return v.value; }
export async function setCache(key:string, value:any, ttlSec:number){ mem.set(key,{ value, exp: Date.now()+ttlSec*1000 }); }
