'use client'
import { Button } from './Button'

type Props = { balance: number; onPick: (amt:number)=>void }

export function RedeemPreset({ balance, onPick }: Props) {
  const opts = [0.25, 0.5, 0.75, 1.0]
  return (
    <div className="flex flex-wrap gap-2">
      {opts.map(p=>(
        <Button key={p} variant="secondary" onClick={()=>onPick(Number((balance*p).toFixed(6)))}>
          {(p*100).toFixed(0)}%
        </Button>
      ))}
    </div>
  )
}
