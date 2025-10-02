'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { SubscriptionPlan, BillingHistory } from '@/types';
import { formatCurrency, formatDate } from '@/lib/utils';
import { 
  ArrowLeft, 
  CreditCard, 
  TrendingUp, 
  Calendar, 
  CheckCircle, 
  AlertCircle,
  Crown,
  Zap,
  Building2,
  BarChart3
} from 'lucide-react';

interface SubscriptionData {
  currentPlan: SubscriptionPlan | null;
  availablePlans: SubscriptionPlan[];
  billingHistory: BillingHistory[];
  usage: {
    staffCount: number;
    activeStaffCount: number;
    receiptsThisMonth: number;
    totalReceipts: number;
    storageUsed: number;
    limits: {
      maxUsers: number;
      maxReceipts: number;
      maxStorage: number;
    };
    usagePercentage: {
      users: number;
      receipts: number;
      storage: number;
    };
    monthlyUsage: Array<{
      month: string;
      receipts: number;
      amount: number;
    }>;
  };
}

export default function SubscriptionPage() {
  const router = useRouter();
  const [data, setData] = useState<SubscriptionData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isChangingPlan, setIsChangingPlan] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);

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

    loadSubscriptionData(token);
  }, [router]);

  const loadSubscriptionData = async (token: string) => {
    try {
      // Load all subscription data
      const [plansRes, billingRes, usageRes] = await Promise.all([
        fetch('/api/subscription/plans', {
          headers: { 'Authorization': `Bearer ${token}` },
        }),
        fetch('/api/subscription/billing', {
          headers: { 'Authorization': `Bearer ${token}` },
        }),
        fetch('/api/subscription/usage', {
          headers: { 'Authorization': `Bearer ${token}` },
        }),
      ]);

      if (!plansRes.ok || !billingRes.ok || !usageRes.ok) {
        throw new Error('Failed to load subscription data');
      }

      const [plansData, billingData, usageData] = await Promise.all([
        plansRes.json(),
        billingRes.json(),
        usageRes.json(),
      ]);

      setData({
        currentPlan: billingData.currentPlan,
        availablePlans: plansData.plans || [],
        billingHistory: billingData.billingHistory || [],
        usage: usageData.usage,
      });

    } catch (error) {
      console.error('Failed to load subscription data:', error);
      setError('Failed to load subscription data');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePlanChange = async (planId: string) => {
    setIsChangingPlan(true);
    setError('');
    setSuccess('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/subscription/change', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ planId }),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error);
      }

      setSuccess(result.message);
      setSelectedPlan(null);
      
      // Reload data
      await loadSubscriptionData(token!);
      
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsChangingPlan(false);
    }
  };

  const getPlanIcon = (planName: string) => {
    switch (planName.toLowerCase()) {
      case 'starter': return <Zap className="h-5 w-5" />;
      case 'professional': return <Building2 className="h-5 w-5" />;
      case 'enterprise': return <Crown className="h-5 w-5" />;
      default: return <CreditCard className="h-5 w-5" />;
    }
  };

  const getPlanColor = (planName: string) => {
    switch (planName.toLowerCase()) {
      case 'starter': return 'bg-blue-500';
      case 'professional': return 'bg-purple-500';
      case 'enterprise': return 'bg-gold-500';
      default: return 'bg-gray-500';
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
          <h1 className="text-2xl font-bold text-gray-900">Failed to load subscription data</h1>
          <Button onClick={() => router.push('/dashboard')} className="mt-4">
            Return to Dashboard
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
                <h1 className="text-2xl font-bold text-gray-900">Subscription Management</h1>
                <p className="text-sm text-gray-600">Manage your subscription and billing</p>
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
            <CheckCircle className="h-4 w-4" />
            <AlertDescription>{success}</AlertDescription>
          </Alert>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Current Plan & Usage */}
          <div className="lg:col-span-2 space-y-6">
            {/* Current Plan */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <CreditCard className="h-5 w-5 mr-2" />
                  Current Plan
                </CardTitle>
              </CardHeader>
              <CardContent>
                {data.currentPlan ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <div className={`p-2 rounded-lg text-white ${getPlanColor(data.currentPlan.name)}`}>
                          {getPlanIcon(data.currentPlan.name)}
                        </div>
                        <div>
                          <h3 className="text-lg font-semibold">{data.currentPlan.name}</h3>
                          <p className="text-sm text-muted-foreground">{data.currentPlan.description}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-2xl font-bold">{formatCurrency(data.currentPlan.price)}</div>
                        <div className="text-sm text-muted-foreground">/{data.currentPlan.billingCycle}</div>
                      </div>
                    </div>

                    <div className="grid grid-cols-3 gap-4 pt-4 border-t">
                      <div className="text-center">
                        <div className="text-2xl font-bold text-blue-600">{data.usage.staffCount}</div>
                        <div className="text-xs text-muted-foreground">Users</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-green-600">{data.usage.receiptsThisMonth}</div>
                        <div className="text-xs text-muted-foreground">Receipts</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-purple-600">{data.usage.storageUsed.toFixed(1)}MB</div>
                        <div className="text-xs text-muted-foreground">Storage</div>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-8">
                    <p className="text-muted-foreground">No active subscription</p>
                    <Button className="mt-4">Choose a Plan</Button>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Usage Analytics */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <BarChart3 className="h-5 w-5 mr-2" />
                  Usage Analytics
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  {/* Usage Bars */}
                  <div className="space-y-4">
                    <div>
                      <div className="flex justify-between text-sm mb-2">
                        <span>Users ({data.usage.staffCount}/{data.usage.limits.maxUsers})</span>
                        <span>{data.usage.usagePercentage.users}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div 
                          className={`h-2 rounded-full ${
                            data.usage.usagePercentage.users > 90 ? 'bg-red-500' :
                            data.usage.usagePercentage.users > 75 ? 'bg-yellow-500' : 'bg-blue-500'
                          }`}
                          style={{ width: `${Math.min(data.usage.usagePercentage.users, 100)}%` }}
                        ></div>
                      </div>
                    </div>

                    <div>
                      <div className="flex justify-between text-sm mb-2">
                        <span>Receipts ({data.usage.receiptsThisMonth}/{data.usage.limits.maxReceipts})</span>
                        <span>{data.usage.usagePercentage.receipts}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div 
                          className={`h-2 rounded-full ${
                            data.usage.usagePercentage.receipts > 90 ? 'bg-red-500' :
                            data.usage.usagePercentage.receipts > 75 ? 'bg-yellow-500' : 'bg-green-500'
                          }`}
                          style={{ width: `${Math.min(data.usage.usagePercentage.receipts, 100)}%` }}
                        ></div>
                      </div>
                    </div>

                    <div>
                      <div className="flex justify-between text-sm mb-2">
                        <span>Storage ({data.usage.storageUsed.toFixed(1)}MB/{data.usage.limits.maxStorage}MB)</span>
                        <span>{data.usage.usagePercentage.storage}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div 
                          className={`h-2 rounded-full ${
                            data.usage.usagePercentage.storage > 90 ? 'bg-red-500' :
                            data.usage.usagePercentage.storage > 75 ? 'bg-yellow-500' : 'bg-purple-500'
                          }`}
                          style={{ width: `${Math.min(data.usage.usagePercentage.storage, 100)}%` }}
                        ></div>
                      </div>
                    </div>
                  </div>

                  {/* Monthly Usage Chart */}
                  <div className="pt-4 border-t">
                    <h4 className="font-medium mb-4">Monthly Usage Trend</h4>
                    <div className="space-y-2">
                      {data.usage.monthlyUsage.map((month, index) => (
                        <div key={index} className="flex items-center justify-between text-sm">
                          <span className="font-medium">{month.month}</span>
                          <div className="flex items-center space-x-4">
                            <span>{month.receipts} receipts</span>
                            <span className="font-semibold">{formatCurrency(month.amount)}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Available Plans & Billing History */}
          <div className="space-y-6">
            {/* Available Plans */}
            <Card>
              <CardHeader>
                <CardTitle>Available Plans</CardTitle>
                <CardDescription>Upgrade or downgrade your subscription</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {data.availablePlans.map((plan) => (
                  <div key={plan.id} className="border rounded-lg p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <div className={`p-1 rounded text-white ${getPlanColor(plan.name)}`}>
                          {getPlanIcon(plan.name)}
                        </div>
                        <div>
                          <h4 className="font-medium">{plan.name}</h4>
                          <p className="text-xs text-muted-foreground">{plan.description}</p>
                        </div>
                      </div>
                      {data.currentPlan?.id === plan.id && (
                        <Badge className="bg-green-100 text-green-800">Current</Badge>
                      )}
                    </div>

                    <div className="text-center py-2">
                      <div className="text-xl font-bold">{formatCurrency(plan.price)}</div>
                      <div className="text-xs text-muted-foreground">/{plan.billingCycle}</div>
                    </div>

                    <div className="space-y-1">
                      <div className="text-xs text-muted-foreground">Features:</div>
                      {plan.features.slice(0, 3).map((feature, index) => (
                        <div key={index} className="flex items-center text-xs">
                          <CheckCircle className="h-3 w-3 text-green-500 mr-2" />
                          {feature}
                        </div>
                      ))}
                    </div>

                    <Dialog>
                      <DialogTrigger asChild>
                        <Button 
                          size="sm" 
                          className="w-full"
                          variant={data.currentPlan?.id === plan.id ? "outline" : "default"}
                          disabled={data.currentPlan?.id === plan.id}
                          onClick={() => setSelectedPlan(plan)}
                        >
                          {data.currentPlan?.id === plan.id ? 'Current Plan' : 'Select Plan'}
                        </Button>
                      </DialogTrigger>
                      <DialogContent>
                        <DialogHeader>
                          <DialogTitle>Confirm Plan Change</DialogTitle>
                          <DialogDescription>
                            Are you sure you want to change to the {plan.name} plan?
                          </DialogDescription>
                        </DialogHeader>
                        <div className="space-y-4">
                          <div className="p-4 bg-gray-50 rounded-lg">
                            <div className="text-center">
                              <h3 className="font-semibold">{plan.name}</h3>
                              <div className="text-2xl font-bold my-2">{formatCurrency(plan.price)}</div>
                              <div className="text-sm text-muted-foreground">/{plan.billingCycle}</div>
                            </div>
                          </div>
                          <div className="flex space-x-2">
                            <Button 
                              variant="outline" 
                              className="flex-1"
                              onClick={() => setSelectedPlan(null)}
                            >
                              Cancel
                            </Button>
                            <Button 
                              className="flex-1"
                              onClick={() => handlePlanChange(plan.id)}
                              disabled={isChangingPlan}
                            >
                              {isChangingPlan ? 'Updating...' : 'Confirm'}
                            </Button>
                          </div>
                        </div>
                      </DialogContent>
                    </Dialog>
                  </div>
                ))}
              </CardContent>
            </Card>

            {/* Billing History */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Calendar className="h-5 w-5 mr-2" />
                  Billing History
                </CardTitle>
              </CardHeader>
              <CardContent>
                {data.billingHistory.length > 0 ? (
                  <div className="space-y-3">
                    {data.billingHistory.slice(0, 5).map((bill) => (
                      <div key={bill.id} className="flex items-center justify-between p-3 border rounded-lg">
                        <div>
                          <div className="font-medium text-sm">{bill.planName}</div>
                          <div className="text-xs text-muted-foreground">
                            {formatDate(bill.billingDate)}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-semibold">{formatCurrency(bill.amount)}</div>
                          <Badge 
                            className={`text-xs ${
                              bill.status === 'paid' 
                                ? 'bg-green-100 text-green-800'
                                : bill.status === 'pending'
                                ? 'bg-yellow-100 text-yellow-800'
                                : 'bg-red-100 text-red-800'
                            }`}
                          >
                            {bill.status}
                          </Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-4 text-muted-foreground">
                    No billing history available
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}