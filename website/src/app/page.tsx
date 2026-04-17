'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Receipt, 
  Users, 
  Mail, 
  BarChart3, 
  Shield, 
  Zap, 
  Clock, 
  Check,
  ArrowRight,
  Star,
  Cloud,
  Smartphone,
  Loader2
} from 'lucide-react';

interface Plan {
  id: string;
  name: string;
  description: string | null;
  price: number;
  billing_cycle: string;
  max_users: number;
  max_receipts_per_month: number | null;
  features: any;
  is_active: boolean;
  created_at: string;
}

interface DisplayPlan {
  id: string;
  name: string;
  description: string;
  price: number;
  billingCycle: string;
  maxUsers: number;
  maxReceipts: number | null;
  features: string[];
  popular: boolean;
}

const features = [
  {
    icon: Receipt,
    title: 'Smart Receipt Capture',
    description: 'Capture receipts with your phone camera and let AI extract all the details'
  },
  {
    icon: Mail,
    title: 'Auto Email Delivery',
    description: 'Automatically send processed receipts to your company email'
  },
  {
    icon: BarChart3,
    title: 'Analytics & Reports',
    description: 'Get insights into spending patterns and generate detailed reports'
  },
  {
    icon: Users,
    title: 'Team Management',
    description: 'Manage your team members and track their receipt submissions'
  },
  {
    icon: Shield,
    title: 'Secure & Compliant',
    description: 'Bank-level security with SOC 2 compliance for your peace of mind'
  },
  {
    icon: Cloud,
    title: 'Cloud Storage',
    description: 'All receipts safely stored in the cloud with automatic backups'
  }
];

export default function LandingPage() {
  const router = useRouter();
  const [plans, setPlans] = useState<DisplayPlan[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPlans();
  }, []);

  const loadPlans = async () => {
    try {
      const response = await fetch('/api/subscription-plans');
      if (response.ok) {
        const data: Plan[] = await response.json();
        
        // Convert database plans to display format
        const displayPlans: DisplayPlan[] = data
          .filter(plan => plan.is_active) // Only show active plans
          .map((plan, index) => {
            // Convert features JSON to array of strings
            const featuresArray: string[] = [];
            
            // Add user and receipt limits
            featuresArray.push(`Up to ${plan.max_users} users`);
            if (plan.max_receipts_per_month) {
              featuresArray.push(`${plan.max_receipts_per_month} receipts per month`);
            } else {
              featuresArray.push('Unlimited receipts per month');
            }
            
            // Add features from JSON
            if (plan.features && typeof plan.features === 'object') {
              Object.entries(plan.features).forEach(([key, value]) => {
                if (typeof value === 'boolean' && value === true) {
                  // For boolean true values, just show the key formatted nicely
                  featuresArray.push(key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()));
                } else if (typeof value === 'string' || typeof value === 'number') {
                  // For string/number values, show key: value
                  const formattedKey = key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
                  featuresArray.push(`${formattedKey}: ${value}`);
                }
              });
            }
            
            // Mark middle plan as popular (or the most expensive one if odd number)
            const popular = index === Math.floor(data.filter(p => p.is_active).length / 2);
            
            return {
              id: plan.id,
              name: plan.name,
              description: plan.description || '',
              price: plan.price,
              billingCycle: plan.billing_cycle,
              maxUsers: plan.max_users,
              maxReceipts: plan.max_receipts_per_month,
              features: featuresArray,
              popular
            };
          })
          .sort((a, b) => a.price - b.price); // Sort by price ascending
        
        setPlans(displayPlans);
      }
    } catch (error) {
      console.error('Failed to load plans:', error);
      // Keep empty plans array on error
    } finally {
      setLoading(false);
    }
  };

  const handleGetStarted = () => {
    router.push('/login');
  };

  const handleSignIn = () => {
    router.push('/login');
  };

  const handlePlanSelect = (planName: string) => {
    // Store selected plan in session storage
    sessionStorage.setItem('selectedPlan', planName);
    router.push('/login');
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white dark:from-gray-900 dark:to-gray-800">
      {/* Navigation */}
      <nav className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <Receipt className="h-8 w-8 text-primary" />
              <span className="ml-2 text-xl font-bold">ReceiptCapture</span>
            </div>
            <div className="flex items-center gap-6">
              <Button 
                variant="ghost" 
                onClick={() => {
                  document.getElementById('pricing')?.scrollIntoView({ behavior: 'smooth' });
                }}
                className="text-base"
              >
                Pricing
              </Button>
              <Button variant="ghost" onClick={handleSignIn}>
                Sign In
              </Button>
              <Button onClick={handleGetStarted}>
                Get Started
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto text-center">
          <Badge className="mb-4" variant="secondary">
            <Zap className="h-3 w-3 mr-1" />
            Trusted by 1000+ Companies
          </Badge>
          <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 dark:from-white dark:to-gray-400">
            Simplify Your Receipt
            <br />
            Management
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
            Capture, process, and manage receipts effortlessly with our mobile app and web portal. 
            Say goodbye to paper receipts and manual data entry.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="text-lg" onClick={handleGetStarted}>
              Start Free Trial
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
            <Button size="lg" variant="outline" className="text-lg" onClick={() => {
              document.getElementById('pricing')?.scrollIntoView({ behavior: 'smooth' });
            }}>
              View Pricing
            </Button>
          </div>
          
          {/* Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-16 max-w-3xl mx-auto">
            <div>
              <div className="text-4xl font-bold text-primary mb-2">10M+</div>
              <div className="text-muted-foreground">Receipts Processed</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-primary mb-2">99.9%</div>
              <div className="text-muted-foreground">Uptime</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-primary mb-2">24/7</div>
              <div className="text-muted-foreground">Support Available</div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gray-50 dark:bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Everything You Need</h2>
            <p className="text-xl text-muted-foreground">
              Powerful features to streamline your receipt management
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {features.map((feature, index) => (
              <Card key={index} className="border-2 hover:border-primary transition-colors">
                <CardHeader>
                  <div className="h-12 w-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4">
                    <feature.icon className="h-6 w-6 text-primary" />
                  </div>
                  <CardTitle>{feature.title}</CardTitle>
                  <CardDescription>{feature.description}</CardDescription>
                </CardHeader>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">How It Works</h2>
            <p className="text-xl text-muted-foreground">
              Get started in three simple steps
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="h-16 w-16 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-4">
                1
              </div>
              <div className="flex justify-center mb-4">
                <Smartphone className="h-12 w-12 text-primary" />
              </div>
              <h3 className="text-xl font-semibold mb-2">Capture Receipt</h3>
              <p className="text-muted-foreground">
                Use your phone to snap a photo of any receipt
              </p>
            </div>
            
            <div className="text-center">
              <div className="h-16 w-16 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-4">
                2
              </div>
              <div className="flex justify-center mb-4">
                <Zap className="h-12 w-12 text-primary" />
              </div>
              <h3 className="text-xl font-semibold mb-2">AI Processing</h3>
              <p className="text-muted-foreground">
                Our AI extracts all details automatically
              </p>
            </div>
            
            <div className="text-center">
              <div className="h-16 w-16 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-4">
                3
              </div>
              <div className="flex justify-center mb-4">
                <Mail className="h-12 w-12 text-primary" />
              </div>
              <h3 className="text-xl font-semibold mb-2">Auto Delivery</h3>
              <p className="text-muted-foreground">
                Receipts are sent to your company email instantly
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 px-4 sm:px-6 lg:px-8 bg-gray-50 dark:bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Simple, Transparent Pricing</h2>
            <p className="text-xl text-muted-foreground">
              Choose the plan that's right for your business
            </p>
          </div>
          
          {loading ? (
            <div className="flex justify-center items-center py-20">
              <Loader2 className="h-12 w-12 animate-spin text-primary" />
            </div>
          ) : plans.length === 0 ? (
            <div className="text-center py-20">
              <p className="text-xl text-muted-foreground">
                No subscription plans available at the moment.
              </p>
            </div>
          ) : (
            <div className={`grid grid-cols-1 ${plans.length === 2 ? 'md:grid-cols-2 max-w-4xl mx-auto' : 'md:grid-cols-3'} gap-8`}>
              {plans.map((plan) => (
                <Card 
                  key={plan.id} 
                  className={`relative ${plan.popular ? 'border-primary border-2 shadow-xl scale-105' : 'border-2'}`}
                >
                  {plan.popular && (
                    <Badge className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                      <Star className="h-3 w-3 mr-1" />
                      Most Popular
                    </Badge>
                  )}
                  <CardHeader>
                    <CardTitle className="text-2xl">{plan.name}</CardTitle>
                    <CardDescription>{plan.description}</CardDescription>
                    <div className="mt-4">
                      <span className="text-4xl font-bold">${plan.price.toFixed(2)}</span>
                      <span className="text-muted-foreground">/{plan.billingCycle}</span>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-3">
                      {plan.features.map((feature, fIndex) => (
                        <li key={fIndex} className="flex items-start gap-2">
                          <Check className="h-5 w-5 text-primary shrink-0 mt-0.5" />
                          <span className="text-sm">{feature}</span>
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                  <CardFooter>
                    <Button 
                      className="w-full" 
                      variant={plan.popular ? 'default' : 'outline'}
                      onClick={() => handlePlanSelect(plan.name)}
                    >
                      Get Started
                    </Button>
                  </CardFooter>
                </Card>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl font-bold mb-4">
            Ready to Transform Your Receipt Management?
          </h2>
          <p className="text-xl text-muted-foreground mb-8">
            Join thousands of companies already using Receipt Capture
          </p>
          <Button size="lg" className="text-lg" onClick={handleGetStarted}>
            Start Your Free Trial
            <ArrowRight className="ml-2 h-5 w-5" />
          </Button>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-12 px-4 sm:px-6 lg:px-8 bg-gray-50 dark:bg-gray-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <Receipt className="h-6 w-6 text-primary" />
                <span className="font-bold">Receipt Capture</span>
              </div>
              <p className="text-sm text-muted-foreground">
                The modern way to manage business receipts
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Product</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-foreground">Features</a></li>
                <li><a href="#pricing" className="hover:text-foreground">Pricing</a></li>
                <li><a href="#" className="hover:text-foreground">Mobile App</a></li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Company</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-foreground">About</a></li>
                <li><a href="#" className="hover:text-foreground">Blog</a></li>
                <li><a href="#" className="hover:text-foreground">Careers</a></li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Support</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-foreground">Help Center</a></li>
                <li><a href="#" className="hover:text-foreground">Contact</a></li>
                <li><a href="#" className="hover:text-foreground">Privacy</a></li>
              </ul>
            </div>
          </div>
          
          <div className="border-t mt-8 pt-8 text-center text-sm text-muted-foreground">
            <p>&copy; 2025 Receipt Capture. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}