'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { User, Company, AppUser } from '@/types';
import { formatCurrency, formatDate } from '@/lib/utils';
import { Users, Receipt, Settings, LogOut, Mail } from 'lucide-react';

interface DashboardData {
  user: User;
  company: Company | null;
  appUsers: AppUser[];
  receiptsCount: number;
}

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<DashboardData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const userStr = localStorage.getItem('user');

    if (!token || !userStr) {
      router.push('/login');
      return;
    }

    const user = JSON.parse(userStr);
    if (user.role !== 'company_representative') {
      router.push('/login');
      return;
    }

    // Load dashboard data
    loadDashboardData(user);
  }, [router]);

  const loadDashboardData = async (user: User) => {
    try {
      // In a real app, these would be API calls
      // For now, we'll simulate the data
      const dashboardData: DashboardData = {
        user,
        company: {
          id: user.companyId || '',
          name: 'Tech Corp Ltd',
          destinationEmail: 'invoices@techcorp.com',
          subscriptionStatus: 'active',
          subscriptionStartDate: new Date().toISOString(),
          createdAt: new Date().toISOString(),
        },
        appUsers: [
          {
            id: '1',
            email: 'staff1@techcorp.com',
            name: 'Alice Johnson',
            companyId: user.companyId || '',
            role: 'employee',
            isActive: true,
            createdBy: user.id,
            createdAt: new Date().toISOString(),
            password: '',
          },
          {
            id: '2',
            email: 'manager@techcorp.com',
            name: 'Bob Wilson',
            companyId: user.companyId || '',
            role: 'manager',
            isActive: true,
            createdBy: user.id,
            createdAt: new Date().toISOString(),
            password: '',
          },
        ],
        receiptsCount: 156,
      };

      setData(dashboardData);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
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
          <h1 className="text-2xl font-bold text-gray-900">Failed to load dashboard</h1>
          <Button onClick={() => router.push('/login')} className="mt-4">
            Return to Login
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Receipt Capture Portal</h1>
              <p className="text-sm text-gray-600">{data.company?.name}</p>
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
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Staff</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{data.appUsers.filter(u => u.isActive).length}</div>
              <p className="text-xs text-muted-foreground">
                Total: {data.appUsers.length} users
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Receipts Processed</CardTitle>
              <Receipt className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{data.receiptsCount}</div>
              <p className="text-xs text-muted-foreground">
                This month
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Subscription</CardTitle>
              <Settings className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold capitalize">{data.company?.subscriptionStatus}</div>
              <p className="text-xs text-muted-foreground">
                Professional Plan
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Company Settings */}
          <Card>
            <CardHeader>
              <CardTitle>Company Settings</CardTitle>
              <CardDescription>Manage your company configuration</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium text-gray-700">Destination Email</label>
                <div className="flex items-center mt-1">
                  <Mail className="h-4 w-4 text-gray-400 mr-2" />
                  <span className="text-sm text-gray-900">{data.company?.destinationEmail}</span>
                </div>
              </div>
              <Button className="w-full">
                <Settings className="h-4 w-4 mr-2" />
                Update Settings
              </Button>
            </CardContent>
          </Card>

          {/* Staff Management */}
          <Card>
            <CardHeader>
              <CardTitle>Staff Management</CardTitle>
              <CardDescription>Manage your staff users</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                {data.appUsers.slice(0, 3).map((user) => (
                  <div key={user.id} className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium">{user.name}</p>
                      <p className="text-xs text-gray-500">{user.email}</p>
                    </div>
                    <span className={`text-xs px-2 py-1 rounded-full ${
                      user.isActive 
                        ? 'bg-green-100 text-green-800' 
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {user.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                ))}
              </div>
              <Button className="w-full">
                <Users className="h-4 w-4 mr-2" />
                Manage Staff
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}