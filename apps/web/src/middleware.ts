export function middleware(request: Request) {
  // Simple pass-through for debugging routing issues
  return new Response(null, { status: 200, headers: { 'x-middleware-hit': '1' } });
}

export const config = {
  matcher: ['/middleware-test']
};