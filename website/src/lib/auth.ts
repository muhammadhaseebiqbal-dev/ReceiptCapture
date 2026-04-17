import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

// Hash password
export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(12);
  return bcrypt.hash(password, salt);
}

// Verify password
export async function verifyPassword(password: string, hashedPassword: string): Promise<boolean> {
  return bcrypt.compare(password, hashedPassword);
}

// Generate JWT token
export function generateToken(userId: string, email: string, role: string, companyId?: string | null): string {
  const secret = process.env.JWT_SECRET || 'receipt-capture-secret-change-in-production-2025';
  
  return jwt.sign(
    {
      userId,
      email,
      role,
      companyId
    },
    secret,
    { expiresIn: '7d' }
  );
}

// Verify JWT token
export function verifyToken(token: string): any {
  const secret = process.env.JWT_SECRET || 'receipt-capture-secret-change-in-production-2025';
  
  try {
    return jwt.verify(token, secret);
  } catch (error) {
    return null;
  }
}