"use client";

import React, { useCallback, useState } from "react";
import Box from "@mui/material/Box";
import Button from "@mui/material/Button";
import CircularProgress from "@mui/material/CircularProgress";
import Typography from "@mui/material/Typography";
import { piLogin } from "@/lib/pi";

export type PiLoginButtonProps = {
  className?: string;
  onLoggedIn?: (auth: { uid: string; username?: string | null; accessToken: string }) => void;
};

export function PiLoginButton({ className, onLoggedIn }: PiLoginButtonProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClick = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { uid, username, accessToken } = await piLogin();
      try {
        localStorage.setItem("hyapiBearer", accessToken);
        (globalThis as any).hyapiBearer = accessToken;
      } catch {}
      try {
        window.dispatchEvent(new CustomEvent("hyapi-auth"));
      } catch {}
      onLoggedIn?.({ uid, username, accessToken });
    } catch (e: any) {
      setError(e?.message || "Login failed");
    } finally {
      setLoading(false);
    }
  }, [onLoggedIn]);

  return (
    <Box className={className} sx={{ display: "inline-flex", flexDirection: "column", gap: 0.5 }}>
      <Button variant="contained" onClick={handleClick} disabled={loading}>
        {loading ? (
          <>
            <CircularProgress size={18} sx={{ mr: 1 }} /> Connecting…
          </>
        ) : (
          "Log in with Pi"
        )}
      </Button>
      {error && <Typography variant="caption" color="error">{error}</Typography>}
    </Box>
  );
}

export default PiLoginButton;
