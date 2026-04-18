'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Check,
  ArrowRight,
  Smartphone,
  Download,
  Loader2,
  AlertCircle
} from 'lucide-react';

interface Plan {
  id: string;
  name: string;
  description: string | null;
  price: number;
  billingCycle: string;
  maxUsers: number;
  maxReceiptsPerMonth: number | null;
  features: string[];
  isActive: boolean;
}

interface DisplayPlan extends Plan {
  popular: boolean;
}

const FLUTTER_APP_LINK = 'https://play.google.com/store/apps/details?id=com.receiptcapture.app';
const FLUTTER_IOS_LINK = 'https://apps.apple.com/app/receiptcapture/id123456789';

export default function PricingPage() {
  const router = useRouter();
  const [plans, setPlans] = useState<DisplayPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadPlans();
  }, []);

  const loadPlans = async () => {
    try {
      const response = await fetch('/api/subscription-plans');
      if (response.ok) {
        const data: Plan[] = await response.json();
        
        const displayPlans: DisplayPlan[] = data
          .filter(plan => plan.isActive)
          .map((plan, index, active) => ({
            ...plan,
            popular: index === Math.floor(active.length / 2)
          }))
          .sort((a, b) => a.price - b.price);
        
        setPlans(displayPlans);
      } else {
        setError('Failed to load pricing plans');
      }
    } catch (err) {
      console.error('Error loading plans:', err);
      setError('Unable to load pricing information');
    } finally {
      setLoading(false);
    }
  };

  const handleStartTrial = (planId: string) => {
    // Save plan selection and redirect to registration
    sessionStorage.setItem('selectedPlanId', planId);
    router.push('/register');
  };

  const handleDownloadApp = (platform: 'android' | 'ios') => {
    const url = platform === 'android' ? FLUTTER_APP_LINK : FLUTTER_IOS_LINK;
    window.open(url, '_blank');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-gray-50 to-white">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-primary mx-auto mb-4" />
          <p className="text-gray-600">Loading pricing plans...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white">
      {/* Header */}
      <header className="border-b bg-white sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Button variant="ghost" onClick={() => router.push('/')}>
            ← Back
          </Button>
          <h1 className="text-2xl font-bold">Pricing</h1>
          <div className="w-20" />
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        {/* Page Title */}
        <div className="text-center mb-16">
          <h2 className="text-4xl sm:text-5xl font-bold mb-4">Simple, Transparent Pricing</h2>
          <p className="text-xl text-gray-600 mb-8">Choose the plan that fits your team's needs</p>
          
          {/* Download App CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
            <Button
              size="lg"
              variant="outline"
              className="gap-2"
              onClick={() => handleDownloadApp('android')}
            >
              <Download className="h-5 w-5" />
              Download for Android
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="gap-2"
              onClick={() => handleDownloadApp('ios')}
            >
              <Download className="h-5 w-5" />
              Download for iOS
            </Button>
          </div>
        </div>

        {/* Error State */}
        {error && (
          <div className="mb-8 p-4 bg-red-50 border border-red-200 rounded-lg flex gap-3 text-red-800">
            <AlertCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
            <p>{error}</p>
          </div>
        )}

        {/* Pricing Cards */}
        {plans.length > 0 ? (
          <div className="grid md:grid-cols-3 gap-8 mb-16">
            {plans.map((plan) => (
              <div key={plan.id} className="relative">
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                    <Badge className="bg-blue-600">Most Popular</Badge>
                  </div>
                )}
                
                <Card className={`h-full flex flex-col ${plan.popular ? 'ring-2 ring-blue-600 shadow-lg' : ''}`}>
                  <CardHeader>
                    <CardTitle className="text-2xl">{plan.name}</CardTitle>
                    <CardDescription>{plan.description}</CardDescription>
                    <div className="mt-4">
                      <span className="text-4xl font-bold">${plan.price}</span>
                      <span className="text-gray-600 ml-2">/{plan.billingCycle}</span>
                    </div>
                  </CardHeader>

                  <CardContent className="flex-1">
                    <div className="space-y-4">
                      {/* Plan Details */}
                      <div className="border-y py-4">
                        <div className="flex justify-between text-sm mb-2">
                          <span className="text-gray-600">Max Users:</span>
                          <span className="font-semibold">{plan.maxUsers}</span>
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-gray-600">Receipts/Month:</span>
                          <span className="font-semibold">
                            {plan.maxReceiptsPerMonth ? `${plan.maxReceiptsPerMonth.toLocaleString()}` : 'Unlimited'}
                          </span>
                        </div>
                      </div>

                      {/* Features */}
                      {plan.features && plan.features.length > 0 && (
                        <div>
                          <h4 className="font-semibold text-sm mb-3">Features:</h4>
                          <ul className="space-y-2">
                            {plan.features.slice(0, 5).map((feature, idx) => (
                              <li key={idx} className="flex items-start gap-2 text-sm">
                                <Check className="h-4 w-4 text-green-600 flex-shrink-0 mt-0.5" />
                                <span>{feature}</span>
                              </li>
                            ))}
                            {plan.features.length > 5 && (
                              <li className="text-xs text-gray-500 mt-2">
                                +{plan.features.length - 5} more features
                              </li>
                            )}
                          </ul>
                        </div>
                      )}
                    </div>
                  </CardContent>

                  <div className="border-t p-6 space-y-3">
                    <Button
                      size="lg"
                      className="w-full"
                      variant={plan.popular ? 'default' : 'outline'}
                      onClick={() => handleStartTrial(plan.id)}
                    >
                      Start Free Trial
                      <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                    
                    <Button
                      size="sm"
                      variant="ghost"
                      className="w-full"
                      onClick={() => handleDownloadApp('android')}
                    >
                      <Smartphone className="h-4 w-4 mr-2" />
                      Get Mobile App
                    </Button>
                  </div>
                </Card>
              </div>
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-gray-600 mb-4">No pricing plans available at this time</p>
            </CardContent>
          </Card>
        )}

        {/* FAQ / Additional Info */}
        <div className="bg-gray-50 rounded-lg p-8 mt-16">
          <h3 className="text-2xl font-bold mb-6">Frequently Asked Questions</h3>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h4 className="font-semibold mb-2">Free Trial</h4>
              <p className="text-gray-600">All plans include a 14-day free trial. No credit card required to get started.</p>
            </div>
            <div>
              <h4 className="font-semibold mb-2">Can I change plans?</h4>
              <p className="text-gray-600">Yes, you can upgrade or downgrade your plan anytime. Changes take effect at the end of your billing cycle.</p>
            </div>
            <div>
              <h4 className="font-semibold mb-2">What payment methods do you accept?</h4>
              <p className="text-gray-600">We accept all major credit cards through our secure Stripe payment processor.</p>
            </div>
            <div>
              <h4 className="font-semibold mb-2">Need help choosing?</h4>
              <p className="text-gray-600">Contact our team at support@receiptcapture.com for personalized recommendations.</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
