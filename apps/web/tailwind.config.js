/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{js,ts,jsx,tsx}',
    './app/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    container: { center: true, padding: '1rem', screens: { lg: '1024px', xl: '1200px', '2xl': '1320px' } },
    extend: {
      colors: {
        brand: {
          50:'#eef7ff',100:'#d9edff',200:'#baddff',300:'#8cc8ff',
          400:'#5ab0ff',500:'#3498ff',600:'#1f7be6',700:'#1a63b8',
          800:'#184f90',900:'#143e70',
        },
        primary: {
          50:'#eef2ff',100:'#e0e7ff',200:'#c7d2fe',300:'#a5b4fc',
          400:'#818cf8',500:'#6366f1',600:'#4f46e5',700:'#4338ca',
          800:'#3730a3',900:'#312e81',
        },
        accent: {
          50:'#effef6',100:'#d9fee8',200:'#b9fbd3',300:'#8ef7ba',
          400:'#59ee9b',500:'#22d88a',600:'#16b67c',700:'#128f67',
          800:'#116f55',900:'#0f5948',
        },
        base: {
          50:'#f8fafc',100:'#f1f5f9',200:'#e2e8f0',300:'#cbd5e1',
          400:'#94a3b8',500:'#64748b',600:'#475569',700:'#334155',
          800:'#1e293b',900:'#0f172a',
        },
        success:'#10b981', warn:'#f59e0b', danger:'#ef4444',
      },
      borderRadius: { xl2: '1rem' },
  boxShadow: { card: '0 8px 24px rgba(2, 6, 23, 0.08)', header: '0 2px 12px rgba(0,0,0,.06)' },
    },
  },
  plugins: [],
}
