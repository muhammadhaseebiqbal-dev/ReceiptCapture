import { User } from '@/types';

export interface AuthResult {
  success: boolean;
  user?: User;
  error?: string;
}

export class AuthService {
  // Simple password validation (in production, use bcrypt)
  validatePassword(plainPassword: string, hashedPassword: string): boolean {
    // For demo purposes, comparing plain text
    // In production: return bcrypt.compare(plainPassword, hashedPassword)
    return plainPassword === hashedPassword;
  }

  // Generate simple session token (in production, use JWT)
  generateToken(user: User): string {
    return btoa(JSON.stringify({ 
      userId: user.id, 
      email: user.email, 
      role: user.role,
      timestamp: Date.now() 
    }));
  }

  // Validate and decode token
  validateToken(token: string): { userId: string; email: string; role: string } | null {
    try {
      const decoded = JSON.parse(atob(token));
      // Simple expiration check (24 hours)
      const isExpired = Date.now() - decoded.timestamp > 24 * 60 * 60 * 1000;
      if (isExpired) return null;
      return decoded;
    } catch {
      return null;
    }
  }
}

export const authService = new AuthService();