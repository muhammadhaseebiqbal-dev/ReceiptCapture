import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { authService } from '@/lib/auth';
import { generateId, isValidEmail } from '@/lib/utils';
import { AppUser } from '@/types';

// GET - Get all staff for a company
export async function GET(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.replace('Bearer ', '');

    if (!token) {
      return NextResponse.json({ error: 'No token provided' }, { status: 401 });
    }

    const decoded = authService.validateToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const user = dataStore.getUserById(decoded.userId);
    if (!user || !user.isActive) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Company representatives can only see their company's staff
    if (user.role === 'company_representative' && user.companyId) {
      const staff = dataStore.getAppUsersByCompany(user.companyId);
      return NextResponse.json({ staff });
    }

    // Master admin can see all staff (with company filter if provided)
    if (user.role === 'master_admin') {
      const { searchParams } = new URL(request.url);
      const companyId = searchParams.get('companyId');
      
      if (companyId) {
        const staff = dataStore.getAppUsersByCompany(companyId);
        return NextResponse.json({ staff });
      } else {
        const allStaff = dataStore.getAppUsers();
        return NextResponse.json({ staff: allStaff });
      }
    }

    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });

  } catch (error) {
    console.error('Get staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST - Create new staff user
export async function POST(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.replace('Bearer ', '');

    if (!token) {
      return NextResponse.json({ error: 'No token provided' }, { status: 401 });
    }

    const decoded = authService.validateToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const user = dataStore.getUserById(decoded.userId);
    if (!user || !user.isActive) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Only company representatives can create staff for their company
    if (user.role !== 'company_representative' || !user.companyId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const { email, name, role, password } = await request.json();

    // Validation
    if (!email || !name || !role || !password) {
      return NextResponse.json({ error: 'All fields are required' }, { status: 400 });
    }

    if (!isValidEmail(email)) {
      return NextResponse.json({ error: 'Invalid email format' }, { status: 400 });
    }

    if (!['manager', 'employee'].includes(role)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
    }

    // Check if email already exists
    const existingUser = dataStore.getUserByEmail(email);
    const existingAppUser = dataStore.getAppUsers().find(u => u.email === email);
    
    if (existingUser || existingAppUser) {
      return NextResponse.json({ error: 'Email already exists' }, { status: 400 });
    }

    // Create new staff user
    const newStaff: AppUser = {
      id: generateId(),
      email,
      name,
      password, // In production: hash this with bcrypt
      companyId: user.companyId,
      role: role as 'manager' | 'employee',
      isActive: true,
      createdBy: user.id,
      createdAt: new Date().toISOString(),
    };

    dataStore.addAppUser(newStaff);

    // Return staff without password
    const { password: _, ...staffWithoutPassword } = newStaff;
    return NextResponse.json({ 
      staff: staffWithoutPassword,
      message: 'Staff user created successfully' 
    }, { status: 201 });

  } catch (error) {
    console.error('Create staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}