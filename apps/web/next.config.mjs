/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    // Proxy API calls to the local backend to avoid cross-origin/localhost in Pi Sandbox
    const target = process.env.NEXT_PUBLIC_API_PROXY_TARGET || 'http://localhost:8080';
    return [
      {
        source: '/api/:path*',
        destination: `${target}/:path*`,
      },
    ];
  },
  // Override devtool in development to avoid Next.js default 'eval-source-map'
  // which violates the Pi Browser CSP (blocks eval / unsafe-eval). This trades
  // some recompilation speed for CSP compliance.
  webpack(config, { dev }) {
    if (dev) {
      // 'cheap-module-source-map' generates external maps without wrapping modules in eval()
      config.devtool = 'cheap-module-source-map';
    }
    return config;
  },
};
export default nextConfig;
