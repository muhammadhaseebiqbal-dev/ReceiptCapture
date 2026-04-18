'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { SubscriptionPlan } from '@/types';
import { formatCurrency } from '@/lib/utils';
import { FORCE_STRIPE_SIMULATION, STRIPE_SIMULATION_MESSAGE } from '@/lib/stripe-mode';
import { 
  Building, 
  Mail, 
  Globe, 
  User, 
  Lock, 
  Check, 
  Crown, 
  Zap, 
  Building2,
  AlertCircle,
  ArrowLeft,
  Smartphone
} from 'lucide-react';

interface RegistrationData {
  // Company Information
  companyName: string;
  companyDomain: string;
  destinationEmail: string;
  
  // Representative Information
  representativeName: string;
  representativeEmail: string;
  representativePassword: string;
  confirmPassword: string;
  
  // Subscription
  selectedPlanId: string;
}

export default function RegisterPage() {
  const router = useRouter();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [plansLoading, setPlansLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [subscriptionPlans, setSubscriptionPlans] = useState<SubscriptionPlan[]>([]);
  
  const [formData, setFormData] = useState<RegistrationData>({
    companyName: '',
    companyDomain: '',
    destinationEmail: '',
    representativeName: '',
    representativeEmail: '',
    representativePassword: '',
    confirmPassword: '',
    selectedPlanId: '',
  });

  useEffect(() => {
    const loadPlans = async () => {
      try {
        const [plansResponse, storedPlanId] = await Promise.all([
          fetch('/api/subscription-plans'),
          Promise.resolve(sessionStorage.getItem('selectedPlanId')),
        ]);

        if (!plansResponse.ok) {
          throw new Error('Failed to load subscription plans');
        }

        const plans = await plansResponse.json();
        const activePlans = Array.isArray(plans)
          ? plans.filter((plan: SubscriptionPlan) => plan.isActive)
          : [];

        setSubscriptionPlans(activePlans);

        if (storedPlanId && activePlans.some((plan: SubscriptionPlan) => plan.id === storedPlanId)) {
          setFormData((previous) => ({ ...previous, selectedPlanId: storedPlanId }));
        } else if (!formData.selectedPlanId && activePlans[0]) {
          setFormData((previous) => ({ ...previous, selectedPlanId: activePlans[0].id }));
        }
      } catch (fetchError) {
        console.error('Failed to load subscription plans:', fetchError);
        setError('Unable to load subscription plans right now. Please try again.');
      } finally {
        setPlansLoading(false);
      }
    };

    void loadPlans();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getPlanIcon = (planName: string) => {
    switch (planName.toLowerCase()) {
      case 'starter': return <Zap className="h-6 w-6" />;
      case 'professional': return <Building2 className="h-6 w-6" />;
      case 'enterprise': return <Crown className="h-6 w-6" />;
      default: return <Building className="h-6 w-6" />;
    }
  };

  const getPlanColor = (planName: string) => {
    switch (planName.toLowerCase()) {
      case 'starter': return 'border-blue-500 bg-blue-50';
      case 'professional': return 'border-purple-500 bg-purple-50';
      case 'enterprise': return 'border-amber-500 bg-amber-50';
      default: return 'border-gray-500 bg-gray-50';
    }
  };

  const handleInputChange = (field: keyof RegistrationData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    setError('');
  };

  const validateStep = (step: number): boolean => {
    setError('');
    
    switch (step) {
      case 1: // Company Information
        if (!formData.companyName.trim()) {
          setError('Company name is required');
          return false;
        }
        if (!formData.destinationEmail.trim()) {
          setError('Destination email is required');
          return false;
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.destinationEmail)) {
          setError('Please enter a valid destination email');
          return false;
        }
        break;
        
      case 2: // Representative Information
        if (!formData.representativeName.trim()) {
          setError('Representative name is required');
          return false;
        }
        if (!formData.representativeEmail.trim()) {
          setError('Representative email is required');
          return false;
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.representativeEmail)) {
          setError('Please enter a valid representative email');
          return false;
        }
        if (!formData.representativePassword) {
          setError('Password is required');
          return false;
        }
        if (formData.representativePassword.length < 8) {
          setError('Password must be at least 8 characters long');
          return false;
        }
        if (formData.representativePassword !== formData.confirmPassword) {
          setError('Passwords do not match');
          return false;
        }
        break;
        
      case 3: // Subscription Plan
        if (!formData.selectedPlanId) {
          setError('Please select a subscription plan');
          return false;
        }
        break;
    }
    
    return true;
  };

  const handleNext = () => {
    if (validateStep(currentStep)) {
      setCurrentStep(prev => prev + 1);
    }
  };

  const handlePrevious = () => {
    setCurrentStep(prev => prev - 1);
  };

  const handleSubmit = async () => {
    if (!validateStep(3)) return;
    
    setIsSubmitting(true);
    setError('');

    try {
      const response = await fetch('/api/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || 'Registration failed');
      }

      const token = result?.token as string | undefined;
      const user = result?.user;

      if (token) {
        localStorage.setItem('token', token);
        document.cookie = `token=${encodeURIComponent(token)}; Path=/; Max-Age=${60 * 60 * 24 * 7}; SameSite=Lax`;
      }

      if (user) {
        localStorage.setItem('user', JSON.stringify(user));
      }

      if (token && formData.selectedPlanId) {
        const checkoutResponse = await fetch('/api/stripe/create-checkout', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
          body: JSON.stringify({
            planId: formData.selectedPlanId,
            flow: 'register',
          }),
        });

        const checkoutResult = await checkoutResponse.json();

        if (checkoutResponse.ok && checkoutResult?.url) {
          window.location.href = checkoutResult.url;
          return;
        }

        if (!checkoutResponse.ok && checkoutResponse.status !== 503) {
          throw new Error(checkoutResult?.error || 'Unable to start Stripe checkout');
        }
      }

      setSuccess(
        FORCE_STRIPE_SIMULATION
          ? 'Registration successful. Stripe simulation step completed and no real payment was made.'
          : 'Registration successful. Stripe checkout is not available yet, so you were registered without payment.'
      );
      
      // Redirect to success page or login after a delay
      setTimeout(() => {
        const selectedPlanName = subscriptionPlans.find((plan) => plan.id === formData.selectedPlanId)?.name;
        const successUrl = FORCE_STRIPE_SIMULATION
          ? `/register/success?stripe=simulated${selectedPlanName ? `&plan=${encodeURIComponent(selectedPlanName)}` : ''}`
          : '/register/success';
        router.push(successUrl);
      }, 2000);
      
    } catch (err: any) {
      setError(err.message || 'Registration failed. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const selectedPlan = subscriptionPlans.find(p => p.id === formData.selectedPlanId);

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <div className="flex items-center justify-center mb-6">
            <div className="flex items-center space-x-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => router.push('/login')}
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Login
              </Button>
            </div>
          </div>
          <h2 className="text-3xl font-bold text-gray-900">Register Your Company</h2>
          <p className="mt-2 text-sm text-gray-600">
            Create your Receipt Capture account and start managing receipts efficiently
          </p>
        </div>

        {/* Progress Steps */}
        <div className="flex items-center justify-center space-x-4">
          {[1, 2, 3].map((step) => (
            <div key={step} className="flex items-center">
              <div className={`
                w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium
                ${currentStep >= step 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-gray-200 text-gray-600'
                }
              `}>
                {currentStep > step ? <Check className="h-4 w-4" /> : step}
              </div>
              {step < 3 && (
                <div className={`w-16 h-0.5 mx-2 ${
                  currentStep > step ? 'bg-blue-600' : 'bg-gray-200'
                }`} />
              )}
            </div>
          ))}
        </div>

        <div className="text-center text-sm text-gray-600">
          {currentStep === 1 && 'Company Information'}
          {currentStep === 2 && 'Representative Details'}
          {currentStep === 3 && 'Choose Your Plan'}
        </div>

        {/* Form Card */}
        <Card>
          <CardContent className="p-8">
            {FORCE_STRIPE_SIMULATION && (
              <Alert className="mb-6 border-amber-400 bg-amber-50 text-amber-900">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{STRIPE_SIMULATION_MESSAGE}</AlertDescription>
              </Alert>
            )}

            {/* Alerts */}
            {error && (
              <Alert variant="destructive" className="mb-6">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
            
            {success && (
              <Alert className="mb-6 border-green-500 text-green-700 bg-green-50">
                <Check className="h-4 w-4" />
                <AlertDescription>{success}</AlertDescription>
              </Alert>
            )}

            {/* Step 1: Company Information */}
            {currentStep === 1 && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Company Information</h3>
                  
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="companyName">Company Name *</Label>
                      <div className="relative">
                        <Building className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="companyName"
                          type="text"
                          placeholder="Your Company Name"
                          value={formData.companyName}
                          onChange={(e) => handleInputChange('companyName', e.target.value)}
                          className="pl-10"
                          required
                        />
                      </div>
                    </div>

                    <div>
                      <Label htmlFor="destinationEmail">Destination Email *</Label>
                      <div className="relative">
                        <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="destinationEmail"
                          type="email"
                          placeholder="invoices@company.com"
                          value={formData.destinationEmail}
                          onChange={(e) => handleInputChange('destinationEmail', e.target.value)}
                          className="pl-10"
                          required
                        />
                      </div>
                      <p className="text-xs text-muted-foreground mt-1">
                        All receipt invoices will be forwarded to this email
                      </p>
                    </div>

                    <div>
                      <Label htmlFor="companyDomain">Company Domain (Optional)</Label>
                      <div className="relative">
                        <Globe className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="companyDomain"
                          type="text"
                          placeholder="company.com"
                          value={formData.companyDomain}
                          onChange={(e) => handleInputChange('companyDomain', e.target.value)}
                          className="pl-10"
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex justify-end">
                  <Button onClick={handleNext} className="w-full sm:w-auto">
                    Next: Representative Details
                  </Button>
                </div>
              </div>
            )}

            {/* Step 2: Representative Information */}
            {currentStep === 2 && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Company Representative</h3>
                  
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="representativeName">Full Name *</Label>
                      <div className="relative">
                        <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="representativeName"
                          type="text"
                          placeholder="John Doe"
                          value={formData.representativeName}
                          onChange={(e) => handleInputChange('representativeName', e.target.value)}
                          className="pl-10"
                          required
                        />
                      </div>
                    </div>

                    <div>
                      <Label htmlFor="representativeEmail">Email Address *</Label>
                      <div className="relative">
                        <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="representativeEmail"
                          type="email"
                          placeholder="john@company.com"
                          value={formData.representativeEmail}
                          onChange={(e) => handleInputChange('representativeEmail', e.target.value)}
                          className="pl-10"
                          required
                        />
                      </div>
                    </div>

                    <div>
                      <Label htmlFor="representativePassword">Password *</Label>
                      <div className="relative">
                        <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="representativePassword"
                          type="password"
                          placeholder="Minimum 8 characters"
                          value={formData.representativePassword}
                          onChange={(e) => handleInputChange('representativePassword', e.target.value)}
                          className="pl-10"
                          required
                        />
                      </div>
                    </div>

                    <div>
                      <Label htmlFor="confirmPassword">Confirm Password *</Label>
                      <div className="relative">
                        <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                        <Input
                          id="confirmPassword"
                          type="password"
                          placeholder="Confirm your password"
                          value={formData.confirmPassword}
                          onChange={(e) => handleInputChange('confirmPassword', e.target.value)}
                          className="pl-10"
                          required
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex justify-between">
                  <Button variant="outline" onClick={handlePrevious}>
                    Previous
                  </Button>
                  <Button onClick={handleNext}>
                    Next: Choose Plan
                  </Button>
                </div>
              </div>
            )}

            {/* Step 3: Subscription Plan */}
            {currentStep === 3 && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-medium text-gray-900 mb-4">Choose Your Plan</h3>
                  {plansLoading ? (
                    <div className="flex items-center justify-center py-16 text-muted-foreground">
                      Loading subscription plans...
                    </div>
                  ) : subscriptionPlans.length === 0 ? (
                    <div className="rounded-lg border border-dashed p-8 text-center text-muted-foreground">
                      No active subscription plans are available right now.
                    </div>
                  ) : (
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {subscriptionPlans.map((plan) => (
                      <div
                        key={plan.id}
                        className={`
                          border-2 rounded-lg p-4 cursor-pointer transition-all
                          ${formData.selectedPlanId === plan.id 
                            ? getPlanColor(plan.name) + ' border-2'
                            : 'border-gray-200 hover:border-gray-300'
                          }
                        `}
                        onClick={() => handleInputChange('selectedPlanId', plan.id)}
                      >
                        <div className="text-center">
                          <div className={`
                            inline-flex p-3 rounded-full mb-3
                            ${formData.selectedPlanId === plan.id 
                              ? getPlanColor(plan.name).includes('blue') ? 'text-blue-600' :
                                getPlanColor(plan.name).includes('purple') ? 'text-purple-600' : 'text-amber-600'
                              : 'text-gray-600'
                            }
                          `}>
                            {getPlanIcon(plan.name)}
                          </div>
                          
                          <h4 className="text-lg font-semibold">{plan.name}</h4>
                          <p className="text-sm text-muted-foreground mb-3">{plan.description}</p>
                          
                          <div className="mb-3">
                            <div className="text-2xl font-bold">{formatCurrency(plan.price)}</div>
                            <div className="text-sm text-muted-foreground">/{plan.billingCycle}</div>
                          </div>

                          <div className="space-y-1 text-xs">
                            <div className="text-left">
                              {plan.features.slice(0, 3).map((feature, index) => (
                                <div key={index} className="flex items-center">
                                  <Check className="h-3 w-3 text-green-500 mr-2" />
                                  {feature}
                                </div>
                              ))}
                              {plan.features.length > 3 && (
                                <div className="text-muted-foreground mt-1">
                                  +{plan.features.length - 3} more features
                                </div>
                              )}
                            </div>
                          </div>

                          {formData.selectedPlanId === plan.id && (
                            <Badge className="mt-3 bg-blue-600">Selected</Badge>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                  )}

                  {selectedPlan && !plansLoading && (
                    <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                      <h4 className="font-medium text-blue-900 mb-2">Plan Summary</h4>
                      <div className="text-sm text-blue-800">
                        <div className="flex justify-between items-center">
                          <span>{selectedPlan.name} Plan</span>
                          <span className="font-semibold">{formatCurrency(selectedPlan.price)}/{selectedPlan.billingCycle}</span>
                        </div>
                        <div className="mt-2 text-xs">
                          • Up to {selectedPlan.maxUsers} users
                          • {selectedPlan.maxReceiptsPerMonth} receipts per month
                          • {selectedPlan.features.join(', ')}
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Mobile App Info */}
                <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center mb-2">
                    <Smartphone className="h-5 w-5 text-gray-600 mr-2" />
                    <h4 className="font-medium text-gray-900">Mobile App Access</h4>
                  </div>
                  <p className="text-sm text-gray-600">
                    After registration, download our mobile app to start capturing receipts. 
                    Your staff will use the mobile app to upload receipts, which will be processed through this web portal.
                  </p>
                </div>

                <div className="flex justify-between">
                  <Button variant="outline" onClick={handlePrevious}>
                    Previous
                  </Button>
                  <Button 
                    onClick={handleSubmit} 
                    disabled={isSubmitting}
                    className="bg-blue-600 hover:bg-blue-700"
                  >
                    {isSubmitting
                      ? 'Creating Account and Redirecting to Stripe...'
                      : FORCE_STRIPE_SIMULATION
                        ? 'Complete Registration and Continue Stripe (Simulated)'
                        : 'Complete Registration and Pay'}
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Footer */}
        <div className="text-center text-sm text-gray-600">
          Already have an account?{' '}
          <Button variant="link" className="p-0 h-auto" onClick={() => router.push('/login')}>
            Sign in here
          </Button>
        </div>
      </div>
    </div>
  );
}