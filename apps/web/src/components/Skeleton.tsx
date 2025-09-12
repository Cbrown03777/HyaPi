import { Skeleton as MuiSkeleton, Card, CardContent, Stack } from '@mui/material';

export function SkeletonBar({ width = '100%', height = 12 }: { width?: number | string; height?: number }) {
  return <MuiSkeleton variant="rounded" width={width} height={height} animation="wave" />;
}

export function SkeletonCard({ lines = 3 }: { lines?: number }) {
  return (
    <Card variant="outlined" sx={{ borderRadius: 3, backdropFilter: 'blur(8px)', background: 'linear-gradient(145deg, rgba(255,255,255,0.04), rgba(255,255,255,0.10))' }}>
      <CardContent>
        <SkeletonBar width="40%" height={16} />
        <Stack spacing={1} sx={{ mt: 2 }}>
          {Array.from({ length: lines }).map((_, i) => (
            <SkeletonBar key={i} height={12} />
          ))}
        </Stack>
      </CardContent>
    </Card>
  );
}
