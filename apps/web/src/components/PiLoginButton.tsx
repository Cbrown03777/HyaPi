"use client";
import { Button } from '@mui/material';
import { piLogin, type PiLoginResult } from '@/lib/pi';

export default function PiLoginButton(props: { onSuccess?: (u: PiLoginResult) => void; label?: string }) {
  const { onSuccess, label } = props;
  return (
    <Button size="small" variant="contained" onClick={async ()=>{
      try {
        const res = await piLogin();
        if (typeof window !== 'undefined') window.dispatchEvent(new Event('hyapi-auth'));
        onSuccess?.(res);
      } catch {}
    }}>{label || 'Log in with Pi'}</Button>
  );
}
