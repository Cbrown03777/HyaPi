// (Metadata moved to parent layout to ensure this page stays server-compatible.)
import GovernanceClient from './GovernanceClient';
import { Box } from '@mui/material';

export default function GovernancePage() {
  return (
    <Box sx={{ maxWidth: 1300, mx: 'auto', px: { xs: 2, md: 4 }, py: 4 }}>
      <GovernanceClient />
    </Box>
  );
}