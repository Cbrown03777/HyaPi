"use client"
import { Dialog, DialogTitle, DialogContent, IconButton } from '@mui/material'
import CloseIcon from '@mui/icons-material/Close'
import { ProofOfReservesPanel } from './ProofOfReservesPanel'

interface Props { open: boolean; onClose: () => void }

export function ProofDialog({ open, onClose }: Props) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle sx={{ pr: 5 }}>
        On‑chain Addresses & Reserves
        <IconButton onClick={onClose} size="small" sx={{ position:'absolute', right:8, top:8 }}>
          <CloseIcon fontSize="small" />
        </IconButton>
      </DialogTitle>
      <DialogContent dividers>
        <ProofOfReservesPanel />
      </DialogContent>
    </Dialog>
  )
}
