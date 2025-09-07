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
};
export default nextConfig;
