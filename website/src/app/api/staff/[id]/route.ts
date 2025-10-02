import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { authService } from '@/lib/auth';
import { isValidEmail } from '@/lib/utils';

interface RouteParams {
  params: { id: string };
}

// PUT - Update staff user
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = params;
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

    // Find the staff user
    const staff = dataStore.getAppUsers().find(s => s.id === id);
    if (!staff) {
      return NextResponse.json({ error: 'Staff user not found' }, { status: 404 });
    }

    // Authorization check
    if (user.role === 'company_representative') {
      if (!user.companyId || staff.companyId !== user.companyId) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
      }
    }

    const { email, name, role, isActive, password } = await request.json();

    // Validation
    if (email && !isValidEmail(email)) {
      return NextResponse.json({ error: 'Invalid email format' }, { status: 400 });
    }

    if (role && !['manager', 'employee'].includes(role)) {
      return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
    }

    // Check if email is being changed and if it already exists
    if (email && email !== staff.email) {
      const existingUser = dataStore.getUserByEmail(email);
      const existingAppUser = dataStore.getAppUsers().find(u => u.email === email && u.id !== id);
      
      if (existingUser || existingAppUser) {
        return NextResponse.json({ error: 'Email already exists' }, { status: 400 });
      }
    }

    // Update staff user
    const updates: Partial<typeof staff> = {};
    if (email !== undefined) updates.email = email;
    if (name !== undefined) updates.name = name;
    if (role !== undefined) updates.role = role;
    if (isActive !== undefined) updates.isActive = isActive;
    if (password !== undefined) updates.password = password; // In production: hash this

    dataStore.updateAppUser(id, updates);

    const updatedStaff = dataStore.getAppUsers().find(s => s.id === id);
    const { password: _, ...staffWithoutPassword } = updatedStaff!;

    return NextResponse.json({
      staff: staffWithoutPassword,
      message: 'Staff user updated successfully'
    });

  } catch (error) {
    console.error('Update staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE - Delete staff user
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;
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

    // Find the staff user
    const staff = dataStore.getAppUsers().find(s => s.id === id);
    if (!staff) {
      return NextResponse.json({ error: 'Staff user not found' }, { status: 404 });
    }

    // Authorization check
    if (user.role === 'company_representative') {
      if (!user.companyId || staff.companyId !== user.companyId) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
      }
    }

    // Delete staff user
    dataStore.deleteAppUser(id);

    return NextResponse.json({
      message: 'Staff user deleted successfully'
    });

  } catch (error) {
    console.error('Delete staff error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}