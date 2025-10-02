// Core types for the application
export interface User {
  id: string;
  email: string;
  password: string; // In production, this would be hashed
  name: string;
  role: 'master_admin' | 'company_representative';
  companyId?: string;
  isActive: boolean;
  createdAt: string;
}

export interface Company {
  id: string;
  name: string;
  domain?: string;
  destinationEmail: string;
  subscriptionPlanId?: string;
  subscriptionStatus: 'inactive' | 'active' | 'cancelled' | 'trial';
  subscriptionStartDate?: string;
  subscriptionEndDate?: string;
  createdAt: string;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  description: string;
  price: number;
  billingCycle: 'monthly' | 'annual';
  maxUsers: number;
  maxReceiptsPerMonth: number;
  features: string[];
  isActive: boolean;
}

export interface AppUser {
  id: string;
  email: string;
  password: string;
  name: string;
  companyId: string;
  role: 'manager' | 'employee';
  isActive: boolean;
  createdBy: string; // Portal user ID who created this user
  createdAt: string;
}

export interface Receipt {
  id: string;
  userId: string;
  companyId: string;
  imagePath: string;
  merchantName?: string;
  amount?: number;
  receiptDate?: string;
  category?: string;
  notes?: string;
  status: 'pending' | 'processed' | 'sent';
  emailSentAt?: string;
  createdAt: string;
}