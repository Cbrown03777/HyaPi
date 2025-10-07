// apps/web/src/types/pi-sdk.d.ts
export {};

export type PiAuthScope = 'username' | 'payments' | 'wallet';

export interface PiSDK {
  init?: (opts: { version: string; network: string }) => void;
  authenticate: (
    opts: { scopes: string[] },
    onIncompletePaymentFound?: (payment: any) => void
  ) => Promise<{
    user?: { uid?: string; username?: string };
    accessToken?: string;
    access_token?: string;
  }>;
  // Other dynamic fields allowed
  [k: string]: any;
}

declare global {
  interface Window {
    Pi?: PiSDK;
    __piReady?: boolean;
    __piInitError?: string;
  }
}
