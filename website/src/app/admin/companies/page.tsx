'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ArrowLeft, Plus, Edit, Trash2, Loader2, Users, Receipt, Calendar, CreditCard } from 'lucide-react';

interface Company {
  id: string;
  name: string;
  domain?: string;
  industry?: string;
  company_size?: string;
  address?: string;
  phone?: string;
  website?: string;
  current_plan_id: string;
  subscription_status: string;
  subscription_start_date: string | null;
  subscription_end_date: string | null;
  created_at: string;
  subscription_plan?: {
    id: string;
    name: string;
    price: number;
    billing_cycle: string;
    max_users: number;
    max_receipts_per_month: number | null;
  };
  representative_count?: number;
  member_count?: number;
  total_user_count?: number;
  receipt_count?: number;
}

interface SubscriptionPlan {
  id: string;
  name: string;
  price: number;
  billing_cycle: string;
  max_users: number;
}

interface FormData {
  name: string;
  domain: string;
  industry: string;
  company_size: string;
  address: string;
  phone: string;
  website: string;
  subscription_plan_id: string;
  subscription_status: string;
  subscription_start_date: string;
  subscription_end_date: string;
}

export default function ManageCompaniesPage() {
  const router = useRouter();
  const [companies, setCompanies] = useState<Company[]>([]);
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingCompany, setEditingCompany] = useState<Company | null>(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [formData, setFormData] = useState<FormData>({
    name: '',
    domain: '',
    industry: '',
    company_size: 'small',
    address: '',
    phone: '',
    website: '',
    subscription_plan_id: '',
    subscription_status: 'trial',
    subscription_start_date: new Date().toISOString().split('T')[0],
    subscription_end_date: '',
  });

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

    loadData(token);
  }, [router]);

  const loadData = async (token: string) => {
    try {
      setIsLoading(true);
      
      // Load companies
      const companiesResponse = await fetch('/api/companies', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (companiesResponse.ok) {
        const companiesData = await companiesResponse.json();
        setCompanies(Array.isArray(companiesData) ? companiesData : []);
      }

      // Load plans
      const plansResponse = await fetch('/api/subscription-plans', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (plansResponse.ok) {
        const plansData = await plansResponse.json();
        setPlans(Array.isArray(plansData) ? plansData : []);
      }
    } catch (error: any) {
      setError(error.message);
      setCompanies([]);
      setPlans([]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleEdit = (company: Company) => {
    setEditingCompany(company);
    setFormData({
      name: company.name,
      domain: company.domain || '',
      industry: company.industry || '',
      company_size: company.company_size || 'small',
      address: company.address || '',
      phone: company.phone || '',
      website: company.website || '',
      subscription_plan_id: company.current_plan_id,
      subscription_status: company.subscription_status,
      subscription_start_date: company.subscription_start_date?.split('T')[0] || '',
      subscription_end_date: company.subscription_end_date?.split('T')[0] || '',
    });
    setIsDialogOpen(true);
  };

  const handleAdd = () => {
    setEditingCompany(null);
    setFormData({
      name: '',
      domain: '',
      industry: '',
      company_size: 'small',
      address: '',
      phone: '',
      website: '',
      subscription_plan_id: '',
      subscription_status: 'trial',
      subscription_start_date: new Date().toISOString().split('T')[0],
      subscription_end_date: '',
    });
    setIsDialogOpen(true);
  };

  const handleSave = async () => {
    try {
      setIsSaving(true);
      setError('');
      setSuccess('');

      const token = localStorage.getItem('token');
      const url = editingCompany
        ? `/api/companies/${editingCompany.id}`
        : '/api/companies';
      
      const method = editingCompany ? 'PUT' : 'POST';

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          ...formData,
          subscription_start_date: formData.subscription_start_date || null,
          subscription_end_date: formData.subscription_end_date || null,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to save company');
      }

      setSuccess(editingCompany ? 'Company updated successfully' : 'Company created successfully');
      setIsDialogOpen(false);
      loadData(token!);
    } catch (error: any) {
      setError(error.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (companyId: string) => {
    if (!confirm('Are you sure you want to delete this company? This action cannot be undone.')) {
      return;
    }

    try {
      setError('');
      setSuccess('');

      const token = localStorage.getItem('token');
      const response = await fetch(`/api/companies/${companyId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to delete company');
      }

      setSuccess('Company deleted successfully');
      loadData(token!);
    } catch (error: any) {
      setError(error.message);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800 border-green-200';
      case 'trial': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'inactive': return 'bg-red-100 text-red-800 border-red-200';
      case 'suspended': return 'bg-orange-100 text-orange-800 border-orange-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getDaysRemaining = (endDate: string | null) => {
    if (!endDate) return null;
    const end = new Date(endDate);
    const now = new Date();
    const diff = Math.ceil((end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    return diff;
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center h-16">
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="sm" onClick={() => router.push('/admin')}>
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back
              </Button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Manage Companies</h1>
                <p className="text-sm text-gray-600">View all registered companies</p>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Alerts */}
        {error && (
          <Alert variant="destructive" className="mb-4">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}
        {success && (
          <Alert className="mb-4 border-green-200 bg-green-50 text-green-800">
            <AlertDescription>{success}</AlertDescription>
          </Alert>
        )}

        {/* Companies Grid */}
        <div className="grid grid-cols-1 gap-6">
          {companies.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <p className="text-gray-500">No companies found. Add your first company to get started.</p>
              </CardContent>
            </Card>
          ) : (
            companies.map((company) => {
              const daysRemaining = getDaysRemaining(company.subscription_end_date);
              const usagePercent = company.subscription_plan?.max_users
                ? ((company.total_user_count || 0) / company.subscription_plan.max_users) * 100
                : 0;

              return (
                <Card key={company.id} className="relative">
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <CardTitle className="text-xl">{company.name}</CardTitle>
                          <Badge className={getStatusColor(company.subscription_status)}>
                            {company.subscription_status}
                          </Badge>
                        </div>
                        <CardDescription className="flex items-center gap-2">
                          {company.industry && <span>{company.industry}</span>}
                          {company.industry && company.company_size && <span>•</span>}
                          {company.company_size && <span className="capitalize">{company.company_size}</span>}
                        </CardDescription>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                      {/* Subscription Plan */}
                      <div className="space-y-1">
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                          <CreditCard className="h-4 w-4" />
                          <span>Subscription Plan</span>
                        </div>
                        <p className="font-semibold">{company.subscription_plan?.name || 'N/A'}</p>
                        <p className="text-sm text-gray-600">
                          ${company.subscription_plan?.price || 0}/{company.subscription_plan?.billing_cycle || 'month'}
                        </p>
                      </div>

                      {/* Users */}
                      <div className="space-y-1">
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                          <Users className="h-4 w-4" />
                          <span>Total Users</span>
                        </div>
                        <p className="font-semibold">
                          {company.total_user_count || 0} / {company.subscription_plan?.max_users || 'Unlimited'}
                        </p>
                        <p className="text-xs text-gray-600">
                          {company.representative_count || 0} reps, {company.member_count || 0} members
                        </p>
                        {company.subscription_plan?.max_users && (
                          <div className="w-full bg-gray-200 rounded-full h-2">
                            <div
                              className={`h-2 rounded-full ${
                                usagePercent > 90 ? 'bg-red-500' : usagePercent > 70 ? 'bg-yellow-500' : 'bg-green-500'
                              }`}
                              style={{ width: `${Math.min(usagePercent, 100)}%` }}
                            />
                          </div>
                        )}
                      </div>

                      {/* Receipts */}
                      <div className="space-y-1">
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                          <Receipt className="h-4 w-4" />
                          <span>Receipts This Month</span>
                        </div>
                        <p className="font-semibold">
                          {company.receipt_count || 0} / {company.subscription_plan?.max_receipts_per_month || 'Unlimited'}
                        </p>
                      </div>

                      {/* Subscription Dates */}
                      <div className="space-y-1">
                        <div className="flex items-center gap-2 text-sm text-gray-500">
                          <Calendar className="h-4 w-4" />
                          <span>Subscription Period</span>
                        </div>
                        <p className="text-sm">
                          <span className="font-medium">Started:</span> {formatDate(company.subscription_start_date)}
                        </p>
                        <p className="text-sm">
                          <span className="font-medium">Expires:</span> {formatDate(company.subscription_end_date)}
                        </p>
                        {daysRemaining !== null && (
                          <p className={`text-sm font-semibold ${
                            daysRemaining < 7 ? 'text-red-600' : daysRemaining < 30 ? 'text-yellow-600' : 'text-green-600'
                          }`}>
                            {daysRemaining > 0 ? `${daysRemaining} days remaining` : 'Expired'}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="mt-4 pt-4 border-t">
                      <p className="text-xs text-gray-500">
                        Registered: {formatDate(company.created_at)}
                      </p>
                    </div>
                  </CardContent>
                </Card>
              );
            })
          )}
        </div>
      </main>

      {/* Add/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingCompany ? 'Edit Company' : 'Add New Company'}</DialogTitle>
            <DialogDescription>
              {editingCompany ? 'Update company details and subscription information' : 'Create a new company with subscription details'}
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Company Name *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="Acme Corporation"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="domain">Domain</Label>
                <Input
                  id="domain"
                  value={formData.domain}
                  onChange={(e) => setFormData({ ...formData, domain: e.target.value })}
                  placeholder="acme.com"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="industry">Industry</Label>
                <Input
                  id="industry"
                  value={formData.industry}
                  onChange={(e) => setFormData({ ...formData, industry: e.target.value })}
                  placeholder="Technology"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="company_size">Company Size</Label>
                <Select
                  value={formData.company_size}
                  onValueChange={(value) => setFormData({ ...formData, company_size: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="small">Small (1-50)</SelectItem>
                    <SelectItem value="medium">Medium (51-200)</SelectItem>
                    <SelectItem value="large">Large (201-1000)</SelectItem>
                    <SelectItem value="enterprise">Enterprise (1000+)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="phone">Phone</Label>
                <Input
                  id="phone"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  placeholder="+1-555-0100"
                />
              </div>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="address">Address</Label>
              <Input
                id="address"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                placeholder="123 Main Street, City, State ZIP"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="website">Website</Label>
              <Input
                id="website"
                value={formData.website}
                onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                placeholder="https://www.acme.com"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="plan">Subscription Plan *</Label>
              <Select
                value={formData.subscription_plan_id}
                onValueChange={(value) => setFormData({ ...formData, subscription_plan_id: value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a plan" />
                </SelectTrigger>
                <SelectContent>
                  {plans.map((plan) => (
                    <SelectItem key={plan.id} value={plan.id}>
                      {plan.name} - ${plan.price}/{plan.billing_cycle}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="status">Subscription Status *</Label>
              <Select
                value={formData.subscription_status}
                onValueChange={(value) => setFormData({ ...formData, subscription_status: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="trial">Trial</SelectItem>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                  <SelectItem value="suspended">Suspended</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="start_date">Start Date</Label>
                <Input
                  id="start_date"
                  type="date"
                  value={formData.subscription_start_date}
                  onChange={(e) => setFormData({ ...formData, subscription_start_date: e.target.value })}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="end_date">End Date</Label>
                <Input
                  id="end_date"
                  type="date"
                  value={formData.subscription_end_date}
                  onChange={(e) => setFormData({ ...formData, subscription_end_date: e.target.value })}
                />
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSaving}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={isSaving}>
              {isSaving && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {editingCompany ? 'Update Company' : 'Create Company'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
