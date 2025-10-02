'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Company, SubscriptionPlan, User } from '@/types';
import { formatCurrency, formatDate } from '@/lib/utils';
import { 
  ArrowLeft, 
  Building, 
  Mail, 
  Globe, 
  CreditCard, 
  Users, 
  Receipt, 
  Check,
  AlertCircle,
  Calendar,
  TrendingUp
} from 'lucide-react';

interface CompanySettingsData {
  user: User;
  company: Company;
  subscriptionPlan: SubscriptionPlan | null;
  usage: {
    staffCount: number;
    activeStaffCount: number;
    receiptsThisMonth: number;
    maxUsers: number;
    maxReceipts: number;
  };
}

export default function CompanySettingsPage() {
  const router = useRouter();
  const [data, setData] = useState<CompanySettingsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    destinationEmail: '',
    domain: '',
  });

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

    loadCompanySettings(token);
  }, [router]);

  const loadCompanySettings = async (token: string) => {
    try {
      const response = await fetch('/api/company/settings', {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to load company settings');
      }

      const result = await response.json();
      const userStr = localStorage.getItem('user');
      const user = JSON.parse(userStr!);

      const settingsData: CompanySettingsData = {
        user,
        company: result.company,
        subscriptionPlan: result.subscriptionPlan,
        usage: result.usage,
      };

      setData(settingsData);
      setFormData({
        name: result.company.name,
        destinationEmail: result.company.destinationEmail,
        domain: result.company.domain || '',
      });

    } catch (error) {
      console.error('Failed to load company settings:', error);
      setError('Failed to load company settings');
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');
    setSuccess('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/company/settings', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(formData),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error);
      }

      setSuccess('Company settings updated successfully!');
      
      // Update local data
      if (data) {
        setData({
          ...data,
          company: result.company,
        });
      }
      
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
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
          <h1 className="text-2xl font-bold text-gray-900">Failed to load company settings</h1>
          <Button onClick={() => router.push('/dashboard')} className="mt-4">
            Return to Dashboard
          </Button>
        </div>
      </div>
    );
  }

  const usagePercentage = {
    users: Math.round((data.usage.staffCount / data.usage.maxUsers) * 100),
    receipts: Math.round((data.usage.receiptsThisMonth / data.usage.maxReceipts) * 100),
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => router.push('/dashboard')}
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Dashboard
              </Button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Company Settings</h1>
                <p className="text-sm text-gray-600">Manage your organization configuration</p>
              </div>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Alerts */}
        {error && (
          <Alert variant="destructive" className="mb-4">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}
        
        {success && (
          <Alert className="mb-4 border-green-500 text-green-700 bg-green-50">
            <Check className="h-4 w-4" />
            <AlertDescription>{success}</AlertDescription>
          </Alert>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Company Information */}
          <div className="lg:col-span-2 space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Building className="h-5 w-5 mr-2" />
                  Company Information
                </CardTitle>
                <CardDescription>
                  Update your company details and receipt forwarding settings
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleUpdateSettings} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="name">Company Name</Label>
                    <div className="relative">
                      <Building className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="name"
                        placeholder="Your Company Name"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        className="pl-10"
                        required
                        disabled={isSubmitting}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="destinationEmail">Destination Email</Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="destinationEmail"
                        type="email"
                        placeholder="invoices@company.com"
                        value={formData.destinationEmail}
                        onChange={(e) => setFormData({ ...formData, destinationEmail: e.target.value })}
                        className="pl-10"
                        required
                        disabled={isSubmitting}
                      />
                    </div>
                    <p className="text-xs text-muted-foreground">
                      All receipt invoices uploaded by staff will be sent to this email
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="domain">Company Domain (Optional)</Label>
                    <div className="relative">
                      <Globe className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="domain"
                        placeholder="company.com"
                        value={formData.domain}
                        onChange={(e) => setFormData({ ...formData, domain: e.target.value })}
                        className="pl-10"
                        disabled={isSubmitting}
                      />
                    </div>
                  </div>

                  <Button type="submit" disabled={isSubmitting} className="w-full">
                    {isSubmitting ? 'Saving...' : 'Save Settings'}
                  </Button>
                </form>
              </CardContent>
            </Card>
          </div>

          {/* Subscription & Usage */}
          <div className="space-y-6">
            {/* Current Plan */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <CreditCard className="h-5 w-5 mr-2" />
                  Current Plan
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {data.subscriptionPlan ? (
                  <>
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold">{data.subscriptionPlan.name}</h3>
                        <p className="text-sm text-muted-foreground">
                          {formatCurrency(data.subscriptionPlan.price)}/{data.subscriptionPlan.billingCycle}
                        </p>
                      </div>
                      <Badge className={`${
                        data.company.subscriptionStatus === 'active' 
                          ? 'bg-green-100 text-green-800'
                          : data.company.subscriptionStatus === 'trial'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {data.company.subscriptionStatus}
                      </Badge>
                    </div>

                    <div className="space-y-2">
                      <h4 className="text-sm font-medium">Features:</h4>
                      <ul className="text-sm text-muted-foreground space-y-1">
                        {data.subscriptionPlan.features.map((feature, index) => (
                          <li key={index} className="flex items-center">
                            <Check className="h-3 w-3 text-green-500 mr-2" />
                            {feature}
                          </li>
                        ))}
                      </ul>
                    </div>

                    {data.company.subscriptionEndDate && (
                      <div className="pt-2 border-t">
                        <div className="flex items-center text-sm text-muted-foreground">
                          <Calendar className="h-4 w-4 mr-2" />
                          Renews: {formatDate(data.company.subscriptionEndDate)}
                        </div>
                      </div>
                    )}

                    <Button variant="outline" className="w-full">
                      Upgrade Plan
                    </Button>
                  </>
                ) : (
                  <div className="text-center py-4">
                    <p className="text-muted-foreground">No active subscription</p>
                    <Button className="mt-2">Choose Plan</Button>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Usage Statistics */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <TrendingUp className="h-5 w-5 mr-2" />
                  Usage Statistics
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Staff Usage */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center">
                      <Users className="h-4 w-4 mr-2 text-muted-foreground" />
                      <span className="text-sm font-medium">Staff Users</span>
                    </div>
                    <span className="text-sm text-muted-foreground">
                      {data.usage.staffCount} / {data.usage.maxUsers}
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${
                        usagePercentage.users > 90 ? 'bg-red-500' :
                        usagePercentage.users > 75 ? 'bg-yellow-500' : 'bg-green-500'
                      }`}
                      style={{ width: `${Math.min(usagePercentage.users, 100)}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {data.usage.activeStaffCount} active users
                  </p>
                </div>

                {/* Receipt Usage */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center">
                      <Receipt className="h-4 w-4 mr-2 text-muted-foreground" />
                      <span className="text-sm font-medium">Receipts</span>
                    </div>
                    <span className="text-sm text-muted-foreground">
                      {data.usage.receiptsThisMonth} / {data.usage.maxReceipts}
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${
                        usagePercentage.receipts > 90 ? 'bg-red-500' :
                        usagePercentage.receipts > 75 ? 'bg-yellow-500' : 'bg-blue-500'
                      }`}
                      style={{ width: `${Math.min(usagePercentage.receipts, 100)}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    This month
                  </p>
                </div>

                {/* Warnings */}
                {(usagePercentage.users > 90 || usagePercentage.receipts > 90) && (
                  <Alert className="border-yellow-500 text-yellow-700 bg-yellow-50">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription className="text-xs">
                      {usagePercentage.users > 90 && 'User limit nearly reached. '}
                      {usagePercentage.receipts > 90 && 'Receipt limit nearly reached. '}
                      Consider upgrading your plan.
                    </AlertDescription>
                  </Alert>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}