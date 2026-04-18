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
import { formatCurrency } from '@/lib/utils';
import { ArrowLeft, Plus, Edit, Trash2, Loader2, Check, X } from 'lucide-react';

// Available features for all plans
const AVAILABLE_FEATURES = [
  'Email Support',
  'Priority Support',
  'Phone Support',
  'Basic Analytics',
  'Advanced Analytics',
  'Receipt Forwarding',
  'Custom Categories',
  'API Access',
  'Unlimited Storage',
  'Dedicated Account Manager',
  'Custom Branding',
  'Bulk Import',
  'Receipt OCR',
  'Multi-language Support',
];

interface SubscriptionPlan {
  id: string;
  name: string;
  description: string | null;
  price: number;
  billing_cycle: string;
  max_users: number;
  max_receipts_per_month: number | null;
  features: string[];
  is_active: boolean;
  created_at: string;
}

interface FormData {
  name: string;
  description: string;
  price: string;
  billing_cycle: string;
  max_users: string;
  max_receipts_per_month: string;
  features: string[];
  is_active: boolean;
}

function normalizePlan(plan: any): SubscriptionPlan {
  // Convert features to array format
  let features: string[] = [];
  if (Array.isArray(plan?.features)) {
    features = plan.features;
  } else if (typeof plan?.features === 'object' && plan.features !== null) {
    // Convert object features to array of keys or key:value strings
    features = Object.entries(plan.features).map(([key, value]) => {
      if (typeof value === 'boolean' && value) {
        return key;
      }
      return value ? `${key}: ${value}` : key;
    });
  }

  return {
    id: String(plan?.id ?? ''),
    name: String(plan?.name ?? ''),
    description: plan?.description ?? null,
    price: Number(plan?.price ?? plan?.pricePerMonth ?? 0),
    billing_cycle: plan?.billing_cycle ?? plan?.billingCycle ?? 'monthly',
    max_users: Number(plan?.max_users ?? plan?.maxUsers ?? 0),
    max_receipts_per_month:
      plan?.max_receipts_per_month ?? plan?.maxReceiptsPerMonth ?? null,
    features,
    is_active: Boolean(plan?.is_active ?? plan?.isActive ?? true),
    created_at: plan?.created_at ?? plan?.createdAt ?? new Date().toISOString(),
  };
}

export default function ManagePlansPage() {
  const router = useRouter();
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editingPlan, setEditingPlan] = useState<SubscriptionPlan | null>(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [formData, setFormData] = useState<FormData>({
    name: '',
    description: '',
    price: '',
    billing_cycle: 'monthly',
    max_users: '',
    max_receipts_per_month: '',
    features: [],
    is_active: true
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

    loadPlans(token);
  }, [router]);

  const loadPlans = async (token: string) => {
    try {
      setIsLoading(true);
      const response = await fetch('/api/subscription-plans', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to load plans');
      }

      const data = await response.json();

      // Normalize both legacy snake_case and backend camelCase responses.
      setPlans(Array.isArray(data) ? data.map(normalizePlan) : []);
    } catch (error: any) {
      setError(error.message);
      setPlans([]); // Set empty array on error
    } finally {
      setIsLoading(false);
    }
  };

  const handleEdit = (plan: SubscriptionPlan) => {
    setEditingPlan(plan);
    setFormData({
      name: plan.name ?? '',
      description: plan.description ?? '',
      price: String(plan.price ?? ''),
      billing_cycle: plan.billing_cycle ?? 'monthly',
      max_users: String(plan.max_users ?? ''),
      max_receipts_per_month: plan.max_receipts_per_month == null ? '' : String(plan.max_receipts_per_month),
      features: Array.isArray(plan.features) ? plan.features : [],
      is_active: Boolean(plan.is_active)
    });
    setIsDialogOpen(true);
  };

  const handleAdd = () => {
    setEditingPlan(null);
    setFormData({
      name: '',
      description: '',
      price: '',
      billing_cycle: 'monthly',
      max_users: '',
      max_receipts_per_month: '',
      features: [],
      is_active: true
    });
    setIsDialogOpen(true);
  };

  const handleSave = async () => {
    try {
      setIsSaving(true);
      setError('');
      setSuccess('');

      // Validation
      if (!formData.name || !formData.price || !formData.max_users) {
        setError('Please fill in all required fields');
        return;
      }

      const token = localStorage.getItem('token');
      const payload = {
        name: formData.name,
        description: formData.description,
        price: formData.price,
        billing_cycle: formData.billing_cycle,
        max_users: formData.max_users,
        max_receipts_per_month: formData.max_receipts_per_month || null,
        features: formData.features,
        is_active: formData.is_active
      };

      const url = editingPlan 
        ? `/api/subscription-plans/${editingPlan.id}`
        : '/api/subscription-plans';
      
      const method = editingPlan ? 'PUT' : 'POST';

      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to save plan');
      }

      setSuccess(editingPlan ? 'Plan updated successfully' : 'Plan created successfully');
      setIsDialogOpen(false);
      loadPlans(token!);

    } catch (error: any) {
      setError(error.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (planId: string) => {
    if (!confirm('Are you sure you want to delete this plan? This action cannot be undone.')) {
      return;
    }

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/subscription-plans/${planId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to delete plan');
      }

      setSuccess('Plan deleted successfully');
      loadPlans(token!);

    } catch (error: any) {
      setError(error.message);
    }
  };

  const handleToggleStatus = async (plan: SubscriptionPlan) => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/subscription-plans/${plan.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          is_active: !plan.is_active
        })
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to update plan status');
      }

      setSuccess('Plan status updated successfully');
      loadPlans(token!);

    } catch (error: any) {
      setError(error.message);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="sm" onClick={() => router.push('/admin')}>
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Admin
              </Button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Manage Subscription Plans</h1>
                <p className="text-sm text-gray-600">Create, edit, and manage pricing plans</p>
              </div>
            </div>
            <Button onClick={handleAdd}>
              <Plus className="h-4 w-4 mr-2" />
              Add New Plan
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Alerts */}
        {error && (
          <Alert variant="destructive" className="mb-6">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {success && (
          <Alert className="mb-6 bg-green-50 border-green-200">
            <Check className="h-4 w-4 text-green-600" />
            <AlertDescription className="text-green-800">{success}</AlertDescription>
          </Alert>
        )}

        {/* Plans Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {plans.map((plan) => (
            <Card key={plan.id} className={`relative ${!plan.is_active ? 'opacity-60' : ''}`}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle>{plan.name}</CardTitle>
                    <CardDescription>{plan.description}</CardDescription>
                  </div>
                  <Badge variant={plan.is_active ? "default" : "secondary"}>
                    {plan.is_active ? 'Active' : 'Inactive'}
                  </Badge>
                </div>
                <div className="mt-4">
                  <span className="text-3xl font-bold">{formatCurrency(plan.price)}</span>
                  <span className="text-gray-600">/{plan.billing_cycle}</span>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 mb-4">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Max Users:</span>
                    <span className="font-medium">{plan.max_users}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Max Receipts:</span>
                    <span className="font-medium">
                      {plan.max_receipts_per_month || 'Unlimited'}/month
                    </span>
                  </div>
                </div>

                {/* Features */}
                {plan.features && Array.isArray(plan.features) && plan.features.length > 0 && (
                  <div className="mb-4">
                    <p className="text-sm font-medium mb-2">Features:</p>
                    <div className="space-y-1">
                      {plan.features.map((feature) => (
                        <div key={feature} className="flex items-start gap-2 text-xs text-gray-600">
                          <Check className="h-3 w-3 text-green-600 mt-0.5 shrink-0" />
                          <span>{feature}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex gap-2 pt-4 border-t">
                  <Button
                    variant="outline"
                    size="sm"
                    className="flex-1"
                    onClick={() => handleEdit(plan)}
                  >
                    <Edit className="h-3 w-3 mr-1" />
                    Edit
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleToggleStatus(plan)}
                  >
                    {plan.is_active ? <X className="h-3 w-3" /> : <Check className="h-3 w-3" />}
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleDelete(plan.id)}
                  >
                    <Trash2 className="h-3 w-3 text-red-600" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {plans.length === 0 && (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-gray-500 mb-4">No subscription plans found</p>
              <Button onClick={handleAdd}>
                <Plus className="h-4 w-4 mr-2" />
                Create Your First Plan
              </Button>
            </CardContent>
          </Card>
        )}
      </main>

      {/* Edit/Add Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingPlan ? 'Edit Subscription Plan' : 'Add New Subscription Plan'}
            </DialogTitle>
            <DialogDescription>
              {editingPlan ? 'Update the plan details below' : 'Create a new subscription plan'}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="name">Plan Name *</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g., Professional"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="billing_cycle">Billing Cycle *</Label>
                <Select
                  value={formData.billing_cycle}
                  onValueChange={(value) => setFormData({ ...formData, billing_cycle: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="monthly">Monthly</SelectItem>
                    <SelectItem value="annual">Annual</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Input
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="e.g., Perfect for growing businesses"
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="price">Price *</Label>
                <Input
                  id="price"
                  type="number"
                  step="0.01"
                  value={formData.price}
                  onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                  placeholder="29.99"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="max_users">Max Users *</Label>
                <Input
                  id="max_users"
                  type="number"
                  value={formData.max_users}
                  onChange={(e) => setFormData({ ...formData, max_users: e.target.value })}
                  placeholder="10"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="max_receipts">Max Receipts/Month</Label>
                <Input
                  id="max_receipts"
                  type="number"
                  value={formData.max_receipts_per_month}
                  onChange={(e) => setFormData({ ...formData, max_receipts_per_month: e.target.value })}
                  placeholder="100 (or leave empty)"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Features</Label>
              <div className="grid grid-cols-2 gap-3 p-3 border rounded-md bg-gray-50">
                {AVAILABLE_FEATURES.map((feature) => (
                  <div key={feature} className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      id={`feature-${feature}`}
                      checked={formData.features.includes(feature)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setFormData({
                            ...formData,
                            features: [...formData.features, feature]
                          });
                        } else {
                          setFormData({
                            ...formData,
                            features: formData.features.filter((f) => f !== feature)
                          });
                        }
                      }}
                      className="rounded"
                    />
                    <Label htmlFor={`feature-${feature}`} className="text-sm cursor-pointer font-normal">
                      {feature}
                    </Label>
                  </div>
                ))}
              </div>
              <p className="text-xs text-gray-500">
                Select all features that should be included in this plan
              </p>
            </div>

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="is_active"
                checked={formData.is_active}
                onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                className="rounded"
              />
              <Label htmlFor="is_active" className="cursor-pointer">
                Plan is active
              </Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSaving}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={isSaving}>
              {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {editingPlan ? 'Update Plan' : 'Create Plan'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
