import { createTheme } from '@mui/material/styles';

// Aave-inspired design tokens (Prompt 1)
// Primary accent: #B6509E, Deep near-black background: #0F0F10, Secondary neutral: #2B2B2B
// Typography stack emphasizes Inter / Manrope with slightly tightened letter-spacing.

export const theme = createTheme({
  cssVariables: true,
  shape: { borderRadius: 12 },
  spacing: 8, // exposed for consistent layout spacing (theme.spacing(n))
  colorSchemes: {
    light: {
      palette: {
        mode: 'light',
        primary: {
          main: '#B6509E',
          contrastText: '#FFFFFF'
        },
        secondary: {
          main: '#2B2B2B',
          contrastText: '#FFFFFF'
        },
        background: {
          default: '#FFFFFF',
          paper: '#F8F9FA'
        },
        text: {
          primary: '#1F2125',
          secondary: '#4A4D55'
        },
        divider: 'rgba(0,0,0,0.1)'
      }
    },
    dark: {
      palette: {
        mode: 'dark',
        primary: {
          main: '#B6509E',
          light: '#C86BB1',
          dark: '#8E3C7C',
          contrastText: '#FFFFFF'
        },
        secondary: {
          main: '#2B2B2B',
          light: '#3A3A3A',
          dark: '#1E1E1E',
          contrastText: '#FFFFFF'
        },
        background: {
          default: '#0F0F10', // near-black canvas
          paper: '#161618'
        },
        text: {
          primary: '#F5F6F7',
          secondary: '#B3B6BD'
        },
        divider: 'rgba(255,255,255,0.08)',
        action: {
          hover: 'rgba(255,255,255,0.08)',
          selected: 'rgba(255,255,255,0.16)',
          disabled: 'rgba(255,255,255,0.3)',
          disabledBackground: 'rgba(255,255,255,0.12)'
        }
      }
    }
  },
  typography: {
    fontFamily: 'Inter, Manrope, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Fira Sans", "Droid Sans", "Helvetica Neue", Arial, sans-serif',
    button: { textTransform: 'none', letterSpacing: '-0.25px', fontWeight: 600 },
    h1: { letterSpacing: '-0.5px', fontWeight: 600 },
    h2: { letterSpacing: '-0.5px', fontWeight: 600 },
    h3: { letterSpacing: '-0.4px', fontWeight: 600 },
    h4: { letterSpacing: '-0.3px', fontWeight: 600 },
    h5: { letterSpacing: '-0.2px', fontWeight: 600 },
    h6: { letterSpacing: '-0.15px', fontWeight: 600 },
    subtitle1: { letterSpacing: '-0.15px' },
    subtitle2: { letterSpacing: '-0.15px' },
    body1: { letterSpacing: '-0.1px' },
    body2: { letterSpacing: '-0.1px' },
    overline: { letterSpacing: '0.5px', fontWeight: 500 }
  },
  // Provide full 25 elevation slots required by MUI (0..24)
  shadows: [
    'none', // 0
    '0 1px 2px 0 rgba(0,0,0,0.25)', // 1
    '0 2px 4px -1px rgba(0,0,0,0.3), 0 1px 2px 0 rgba(0,0,0,0.2)', // 2
    '0 2px 6px -1px rgba(0,0,0,0.35), 0 2px 4px -1px rgba(0,0,0,0.25)', // 3
    '0 3px 8px -1px rgba(0,0,0,0.4), 0 3px 6px -2px rgba(0,0,0,0.3)', // 4
    '0 4px 10px -2px rgba(0,0,0,0.45), 0 2px 4px -1px rgba(0,0,0,0.25)', // 5
    '0 6px 12px -2px rgba(0,0,0,0.5), 0 4px 6px -2px rgba(0,0,0,0.35)', // 6
    '0 8px 16px -2px rgba(0,0,0,0.55), 0 6px 8px -2px rgba(0,0,0,0.4)', // 7
    '0 10px 18px -3px rgba(0,0,0,0.6), 0 6px 10px -2px rgba(0,0,0,0.45)', // 8
    '0 12px 20px -3px rgba(0,0,0,0.6), 0 8px 12px -2px rgba(0,0,0,0.5)', // 9
    '0 14px 22px -4px rgba(0,0,0,0.65), 0 8px 14px -2px rgba(0,0,0,0.5)', // 10
    '0 16px 24px -4px rgba(0,0,0,0.65), 0 10px 16px -2px rgba(0,0,0,0.55)', // 11
    '0 18px 26px -4px rgba(0,0,0,0.7), 0 10px 18px -3px rgba(0,0,0,0.55)', // 12
    '0 20px 28px -4px rgba(0,0,0,0.7), 0 12px 20px -3px rgba(0,0,0,0.55)', // 13
    '0 22px 30px -5px rgba(0,0,0,0.7), 0 12px 22px -3px rgba(0,0,0,0.55)', // 14
    '0 24px 32px -5px rgba(0,0,0,0.75), 0 14px 24px -3px rgba(0,0,0,0.6)', // 15
    '0 26px 34px -5px rgba(0,0,0,0.75), 0 14px 26px -3px rgba(0,0,0,0.6)', // 16
    '0 28px 36px -6px rgba(0,0,0,0.75), 0 16px 28px -4px rgba(0,0,0,0.6)', // 17
    '0 30px 38px -6px rgba(0,0,0,0.75), 0 16px 30px -4px rgba(0,0,0,0.6)', // 18
    '0 32px 40px -6px rgba(0,0,0,0.75), 0 18px 32px -4px rgba(0,0,0,0.6)', // 19
    '0 34px 42px -7px rgba(0,0,0,0.75), 0 18px 34px -4px rgba(0,0,0,0.6)', // 20
    '0 36px 44px -7px rgba(0,0,0,0.8), 0 20px 36px -4px rgba(0,0,0,0.65)', // 21
    '0 38px 46px -7px rgba(0,0,0,0.8), 0 20px 38px -4px rgba(0,0,0,0.65)', // 22
    '0 40px 48px -8px rgba(0,0,0,0.8), 0 22px 40px -5px rgba(0,0,0,0.65)', // 23
    '0 42px 50px -8px rgba(0,0,0,0.85), 0 24px 42px -5px rgba(0,0,0,0.7)' // 24
  ],
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        ':root': {
          '--scroll-behavior': 'smooth'
        },
        body: {
          backgroundColor: 'var(--mui-palette-background-default)'
        }
      }
    },
    MuiButton: {
      defaultProps: { size: 'medium' },
      styleOverrides: {
        root: {
          fontWeight: 600,
          borderRadius: 12,
          letterSpacing: '-0.25px'
        }
      }
    },
    MuiTableCell: {
      defaultProps: { size: 'small' }
    },
    MuiPaper: {
      styleOverrides: {
        rounded: { borderRadius: 12, backgroundImage: 'none' }
      }
    }
  }
});

export default theme;
