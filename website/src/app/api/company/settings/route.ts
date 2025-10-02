import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { authService } from '@/lib/auth';
import { isValidEmail } from '@/lib/utils';

// GET - Get company settings
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

    // Only company representatives can access their company settings
    if (user.role !== 'company_representative' || !user.companyId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const company = dataStore.getCompanyById(user.companyId);
    if (!company) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    // Get subscription plan details
    let subscriptionPlan = null;
    if (company.subscriptionPlanId) {
      subscriptionPlan = dataStore.getSubscriptionPlanById(company.subscriptionPlanId);
    }

    // Get usage statistics
    const staffCount = dataStore.getAppUsersByCompany(user.companyId).length;
    const activeStaffCount = dataStore.getAppUsersByCompany(user.companyId).filter(u => u.isActive).length;

    return NextResponse.json({
      company,
      subscriptionPlan,
      usage: {
        staffCount,
        activeStaffCount,
        receiptsThisMonth: 156, // Mock data - in real app, calculate from receipts
        maxUsers: subscriptionPlan?.maxUsers || 0,
        maxReceipts: subscriptionPlan?.maxReceiptsPerMonth || 0,
      }
    });

  } catch (error) {
    console.error('Get company settings error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// PUT - Update company settings
export async function PUT(request: NextRequest) {
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

    // Only company representatives can update their company settings
    if (user.role !== 'company_representative' || !user.companyId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const company = dataStore.getCompanyById(user.companyId);
    if (!company) {
      return NextResponse.json({ error: 'Company not found' }, { status: 404 });
    }

    const { name, destinationEmail, domain } = await request.json();

    // Validation
    if (!destinationEmail || !isValidEmail(destinationEmail)) {
      return NextResponse.json({ error: 'Valid destination email is required' }, { status: 400 });
    }

    if (!name || name.trim().length < 2) {
      return NextResponse.json({ error: 'Company name must be at least 2 characters' }, { status: 400 });
    }

    // Update company
    const updates: any = {
      name: name.trim(),
      destinationEmail: destinationEmail.toLowerCase(),
      updatedAt: new Date().toISOString(),
    };

    if (domain !== undefined) {
      updates.domain = domain?.trim() || null;
    }

    dataStore.updateCompany(user.companyId, updates);

    const updatedCompany = dataStore.getCompanyById(user.companyId);

    return NextResponse.json({
      company: updatedCompany,
      message: 'Company settings updated successfully'
    });

  } catch (error) {
    console.error('Update company settings error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}