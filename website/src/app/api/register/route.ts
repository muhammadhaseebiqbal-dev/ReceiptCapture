import { NextRequest, NextResponse } from 'next/server';
import { dataStore } from '@/lib/data-store';
import { authService } from '@/lib/auth';
import { User, Company } from '@/types';

interface RegistrationRequest {
  // Company Information
  companyName: string;
  companyDomain?: string;
  destinationEmail: string;
  
  // Representative Information
  representativeName: string;
  representativeEmail: string;
  representativePassword: string;
  
  // Subscription
  selectedPlanId: string;
}

export async function POST(request: NextRequest) {
  try {
    const {
      companyName,
      companyDomain,
      destinationEmail,
      representativeName,
      representativeEmail,
      representativePassword,
      selectedPlanId,
    }: RegistrationRequest = await request.json();

    // Validation
    if (!companyName || !destinationEmail || !representativeName || !representativeEmail || !representativePassword || !selectedPlanId) {
      return NextResponse.json(
        { error: 'All required fields must be provided' },
        { status: 400 }
      );
    }

    // Check if user already exists
    const existingUser = dataStore.getUserByEmail(representativeEmail);
    if (existingUser) {
      return NextResponse.json(
        { error: 'A user with this email already exists' },
        { status: 400 }
      );
    }

    // Validate subscription plan
    const subscriptionPlan = dataStore.getSubscriptionPlan(selectedPlanId);
    if (!subscriptionPlan) {
      return NextResponse.json(
        { error: 'Invalid subscription plan selected' },
        { status: 400 }
      );
    }

    // Generate IDs
    const companyId = `company_${Date.now()}`;
    const userId = `user_${Date.now()}`;
    const now = new Date().toISOString();
    
    // Calculate subscription end date (30 days trial)
    const subscriptionEndDate = new Date();
    subscriptionEndDate.setDate(subscriptionEndDate.getDate() + 30);

    // Create company
    const company: Company = {
      id: companyId,
      name: companyName,
      domain: companyDomain,
      destinationEmail,
      subscriptionPlanId: selectedPlanId,
      subscriptionStatus: 'trial', // Start with trial
      subscriptionStartDate: now,
      subscriptionEndDate: subscriptionEndDate.toISOString(),
      createdAt: now,
    };

    // Create company representative user
    const user: User = {
      id: userId,
      email: representativeEmail,
      password: representativePassword, // In production, hash this
      name: representativeName,
      role: 'company_representative',
      companyId,
      isActive: true,
      createdAt: now,
    };

    // Save to data store
    dataStore.addCompany(company);
    dataStore.addUser(user);

    // Create initial billing entry for trial
    const billingEntry = {
      id: `bill_${Date.now()}`,
      companyId,
      planId: selectedPlanId,
      planName: subscriptionPlan.name,
      amount: 0, // Trial period
      billingCycle: subscriptionPlan.billingCycle,
      status: 'paid',
      billingDate: now,
      nextBillingDate: subscriptionEndDate.toISOString(),
      description: `30-day trial for ${subscriptionPlan.name} plan`,
      createdAt: now,
    };

    dataStore.addBillingHistory(billingEntry);

    // Generate authentication token
    const token = authService.generateToken(user);

    return NextResponse.json({
      success: true,
      message: 'Company registration successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        companyId: user.companyId,
      },
      company: {
        id: company.id,
        name: company.name,
        destinationEmail: company.destinationEmail,
        subscriptionStatus: company.subscriptionStatus,
      },
      token,
      subscriptionPlan: {
        name: subscriptionPlan.name,
        trialEndDate: subscriptionEndDate.toISOString(),
      },
    });

  } catch (error) {
    console.error('Registration error:', error);
    return NextResponse.json(
      { error: 'Internal server error during registration' },
      { status: 500 }
    );
  }
}