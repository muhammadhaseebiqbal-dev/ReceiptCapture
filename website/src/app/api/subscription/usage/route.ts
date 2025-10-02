import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { verifyToken } from '@/lib/auth';

export async function GET(request: NextRequest) {
  try {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = verifyToken(token);
    if (!payload || payload.role !== 'company_representative') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Get current user and company
    const user = dataStore.getUser(payload.userId);
    if (!user || !user.companyId) {
      return NextResponse.json({ error: 'User or company not found' }, { status: 404 });
    }

    const company = dataStore.getCompany(user.companyId);
    const currentPlan = company?.subscriptionPlanId 
      ? dataStore.getSubscriptionPlan(company.subscriptionPlanId)
      : null;

    // Get usage statistics
    const staffUsers = dataStore.getAppUsersByCompany(user.companyId);
    const receipts = dataStore.getReceiptsByCompany(user.companyId);

    // Calculate monthly usage
    const currentMonth = new Date().getMonth();
    const currentYear = new Date().getFullYear();
    const receiptsThisMonth = receipts.filter(receipt => {
      const receiptDate = new Date(receipt.createdAt);
      return receiptDate.getMonth() === currentMonth && receiptDate.getFullYear() === currentYear;
    });

    // Calculate usage over last 6 months
    const monthlyUsage = [];
    for (let i = 5; i >= 0; i--) {
      const date = new Date();
      date.setMonth(date.getMonth() - i);
      const month = date.getMonth();
      const year = date.getFullYear();
      
      const monthReceipts = receipts.filter(receipt => {
        const receiptDate = new Date(receipt.createdAt);
        return receiptDate.getMonth() === month && receiptDate.getFullYear() === year;
      });

      monthlyUsage.push({
        month: date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
        receipts: monthReceipts.length,
        amount: monthReceipts.reduce((sum, r) => sum + (r.amount || 0), 0),
      });
    }

    // Plan limits
    const limits = {
      maxUsers: currentPlan?.limits?.maxUsers || 5,
      maxReceipts: currentPlan?.limits?.maxReceipts || 100,
      maxStorage: currentPlan?.limits?.maxStorage || 1000, // MB
    };

    const usage = {
      staffCount: staffUsers.length,
      activeStaffCount: staffUsers.filter(u => u.isActive).length,
      receiptsThisMonth: receiptsThisMonth.length,
      totalReceipts: receipts.length,
      storageUsed: receipts.length * 0.5, // Simulate 0.5MB per receipt
      limits,
      monthlyUsage,
      usagePercentage: {
        users: Math.round((staffUsers.length / limits.maxUsers) * 100),
        receipts: Math.round((receiptsThisMonth.length / limits.maxReceipts) * 100),
        storage: Math.round(((receipts.length * 0.5) / limits.maxStorage) * 100),
      },
    };

    return NextResponse.json({
      usage,
      currentPlan,
      company: {
        subscriptionStatus: company?.subscriptionStatus,
        subscriptionEndDate: company?.subscriptionEndDate,
      },
    });

  } catch (error) {
    console.error('Usage analytics error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}