// Prefer relative base so Pi Browser and non-localhost clients can reach the API via Next proxy
export const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '/api';
