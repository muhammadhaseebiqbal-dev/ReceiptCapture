import { NextRequest, NextResponse } from 'next/server';

// Middleware to check subscription status before accessing dashboard/portal
export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Routes that require subscription status check
  const protectedRoutes = ['/dashboard', '/admin'];
  
  // Only check for protected routes
  if (!protectedRoutes.some(route => pathname.startsWith(route))) {
    return NextResponse.next();
  }

  // Get token from cookies
  const token = request.cookies.get('token')?.value;
  
  // If no token, redirect to login
  if (!token) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    return NextResponse.redirect(url);
  }

  // Token exists, allow access - subscription check happens in the page component
  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*', '/portal/:path*']
};
