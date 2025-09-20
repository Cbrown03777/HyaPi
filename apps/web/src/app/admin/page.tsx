import { Box, Typography, Paper } from '@mui/material';
import AllocatorRow from '@/components/admin/AllocatorRow';

export default function AdminIndex() {
	return (
		<Box sx={{ maxWidth: 860, mx: 'auto', py: 4, px: { xs: 2, sm: 3 }, display: 'flex', flexDirection: 'column', gap: 4 }}>
			<Box component="header">
				<Typography variant="h5" fontWeight={600}>Admin</Typography>
				<Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>Internal operational panels. Use navigation to access specific tools.</Typography>
			</Box>
	      <AllocatorRow />
			<Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' } }}>
				<Paper
						component="a"
						href="/admin/alloc"
						variant="outlined"
						sx={{
							display: 'block',
							p: 2.5,
							textDecoration: 'none',
							cursor: 'pointer',
							borderRadius: 3,
							background: 'linear-gradient(145deg, rgba(255,255,255,0.04), rgba(255,255,255,0.10))',
							transition: 'border-color .25s, box-shadow .25s',
							'&:hover': { borderColor: 'primary.main', boxShadow: 4 },
							'&:focus-visible': { outline: '2px solid', outlineColor: 'primary.main' }
						}}
					>
						<Typography variant="subtitle1" fontWeight={600} sx={{ mb: 0.5 }}>Allocation Planner</Typography>
						<Typography variant="caption" color="text.secondary">Preview and simulate rebalances across venues.</Typography>
				</Paper>
			</Box>
		</Box>
	);
}
