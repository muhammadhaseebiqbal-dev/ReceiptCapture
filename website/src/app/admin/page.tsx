'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { User, Company, SubscriptionPlan } from '@/types';
import { formatCurrency, formatDate } from '@/lib/utils';
import { Building, Users, CreditCard, Settings, LogOut, TrendingUp } from 'lucide-react';

interface AdminData {
  user: User;
  companies: Company[];
  subscriptionPlans: SubscriptionPlan[];
  totalRevenue: number;
  totalUsers: number;
}

export default function AdminPage() {
  const router = useRouter();
  const [data, setData] = useState<AdminData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const userStr = localStorage.getItem('user');

    if (!token || !userStr) {
      router.push('/login');
      return;
    }

    const user = JSON.parse(userStr);
    if (user.role !== 'master_admin') {
      router.push('/login');
      return;
    }

    // Load admin data
    loadAdminData(user);
  }, [router]);

  const loadAdminData = async (user: User) => {
    try {
      // Simulate API calls with mock data
      const adminData: AdminData = {
        user,
        companies: [
          {
            id: '1',
            name: 'Tech Corp Ltd',
            destinationEmail: 'invoices@techcorp.com',
            subscriptionStatus: 'active',
            subscriptionStartDate: new Date().toISOString(),
            createdAt: new Date().toISOString(),
          },
          {
            id: '2', 
            name: 'Marketing Inc',
            destinationEmail: 'receipts@marketing.com',
            subscriptionStatus: 'trial',
            subscriptionStartDate: new Date().toISOString(),
            createdAt: new Date().toISOString(),
          },
          {
            id: '3',
            name: 'Startup LLC',
            destinationEmail: 'billing@startup.com',
            subscriptionStatus: 'inactive',
            createdAt: new Date().toISOString(),
          },
        ],
        subscriptionPlans: [
          {
            id: '1',
            name: 'Starter',
            description: 'Perfect for small teams',
            price: 29.99,
            billingCycle: 'monthly',
            maxUsers: 5,
            maxReceiptsPerMonth: 100,
            features: ['Email Support', '1GB Storage'],
            isActive: true,
          },
          {
            id: '2',
            name: 'Professional', 
            description: 'Growing businesses',
            price: 59.99,
            billingCycle: 'monthly',
            maxUsers: 20,
            maxReceiptsPerMonth: 500,
            features: ['Priority Support', '10GB Storage', 'Analytics'],
            isActive: true,
          },
          {
            id: '3',
            name: 'Enterprise',
            description: 'Large organizations', 
            price: 149.99,
            billingCycle: 'monthly',
            maxUsers: 100,
            maxReceiptsPerMonth: 2000,
            features: ['Phone Support', 'Unlimited Storage', 'API Access'],
            isActive: true,
          },
        ],
        totalRevenue: 15420.50,
        totalUsers: 87,
      };

      setData(adminData);
    } catch (error) {
      console.error('Failed to load admin data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    router.push('/login');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900">Failed to load admin panel</h1>
          <Button onClick={() => router.push('/login')} className="mt-4">
            Return to Login
          </Button>
        </div>
      </div>
    );
  }

  const activeCompanies = data.companies.filter(c => c.subscriptionStatus === 'active').length;
  const trialCompanies = data.companies.filter(c => c.subscriptionStatus === 'trial').length;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Master Admin Panel</h1>
              <p className="text-sm text-gray-600">Receipt Capture Portal</p>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">Welcome, {data.user.name}</span>
              <Button variant="outline" size="sm" onClick={handleLogout}>
                <LogOut className="h-4 w-4 mr-2" />
                Logout
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Companies</CardTitle>
              <Building className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{data.companies.length}</div>
              <p className="text-xs text-muted-foreground">
                {activeCompanies} active, {trialCompanies} trial
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Users</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{data.totalUsers}</div>
              <p className="text-xs text-muted-foreground">
                Across all companies
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Monthly Revenue</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{formatCurrency(data.totalRevenue)}</div>
              <p className="text-xs text-muted-foreground">
                +12.5% from last month
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Plans</CardTitle>
              <CreditCard className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{data.subscriptionPlans.filter(p => p.isActive).length}</div>
              <p className="text-xs text-muted-foreground">
                Subscription plans
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Management Sections */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Companies */}
          <Card>
            <CardHeader>
              <CardTitle>Recent Companies</CardTitle>
              <CardDescription>Latest registered companies</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {data.companies.slice(0, 4).map((company) => (
                <div key={company.id} className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">{company.name}</p>
                    <p className="text-xs text-gray-500">{company.destinationEmail}</p>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    company.subscriptionStatus === 'active' 
                      ? 'bg-green-100 text-green-800'
                      : company.subscriptionStatus === 'trial'
                      ? 'bg-yellow-100 text-yellow-800' 
                      : 'bg-red-100 text-red-800'
                  }`}>
                    {company.subscriptionStatus}
                  </span>
                </div>
              ))}
              <Button className="w-full">
                <Building className="h-4 w-4 mr-2" />
                Manage Companies
              </Button>
            </CardContent>
          </Card>

          {/* Subscription Plans */}
          <Card>
            <CardHeader>
              <CardTitle>Subscription Plans</CardTitle>
              <CardDescription>Available pricing plans</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {data.subscriptionPlans.map((plan) => (
                <div key={plan.id} className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">{plan.name}</p>
                    <p className="text-xs text-gray-500">{formatCurrency(plan.price)}/{plan.billingCycle}</p>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    plan.isActive 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-gray-100 text-gray-800'
                  }`}>
                    {plan.isActive ? 'Active' : 'Inactive'}
                  </span>
                </div>
              ))}
              <Button className="w-full">
                <CreditCard className="h-4 w-4 mr-2" />
                Manage Plans
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}