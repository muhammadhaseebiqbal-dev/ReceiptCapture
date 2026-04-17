'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Loader2, Mail, Lock, Eye, EyeOff, Receipt, ArrowLeft, CheckCircle2, Shield } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectedPlan, setSelectedPlan] = useState<string | null>(null);

  useEffect(() => {
    // Check if user came from pricing section
    const plan = sessionStorage.getItem('selectedPlan');
    if (plan) {
      setSelectedPlan(plan);
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Login failed');
      }

      // Store token and user data
      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));

      // Clear selected plan from session
      sessionStorage.removeItem('selectedPlan');

      // Redirect based on role
      if (data.user.role === 'master_admin') {
        router.push('/admin');
      } else {
        router.push('/dashboard');
      }
      
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoLogin = (demoEmail: string, demoPassword: string) => {
    setEmail(demoEmail);
    setPassword(demoPassword);
  };

  return (
    <div className="min-h-screen flex">
      {/* Left side - Login Form */}
      <div className="flex-1 flex items-center justify-center px-4 sm:px-6 lg:px-8 bg-white dark:bg-gray-900">
        <div className="w-full max-w-md">
          {/* Back to home */}
          <Button 
            variant="ghost" 
            className="mb-6"
            onClick={() => router.push('/')}
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Home
          </Button>

          <Card className="border-2">
            <CardHeader className="space-y-1">
              <div className="flex items-center justify-center mb-4">
                <div className="h-12 w-12 bg-primary/10 rounded-xl flex items-center justify-center">
                  <Receipt className="h-6 w-6 text-primary" />
                </div>
              </div>
              <CardTitle className="text-2xl font-bold text-center">
                Welcome Back
              </CardTitle>
              <CardDescription className="text-center">
                {selectedPlan ? (
                  <div className="flex items-center justify-center gap-2 mt-2">
                    <span>Selected plan:</span>
                    <Badge variant="secondary">{selectedPlan}</Badge>
                  </div>
                ) : (
                  'Sign in to your account to continue'
                )}
              </CardDescription>
            </CardHeader>
            
            <form onSubmit={handleSubmit}>
              <CardContent className="space-y-4">
                {error && (
                  <Alert variant="destructive">
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                <div className="space-y-2">
                  <Label htmlFor="email">Email Address</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="email"
                      type="email"
                      placeholder="you@company.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="pl-10"
                      required
                      disabled={isLoading}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label htmlFor="password">Password</Label>
                    <a href="#" className="text-xs text-primary hover:underline">
                      Forgot password?
                    </a>
                  </div>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Enter your password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="pl-10 pr-10"
                      required
                      disabled={isLoading}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-3 text-muted-foreground hover:text-foreground transition-colors"
                      disabled={isLoading}
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                <Button type="submit" className="w-full" size="lg" disabled={isLoading}>
                  {isLoading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Signing in...
                    </>
                  ) : (
                    'Sign In'
                  )}
                </Button>

                {/* Divider */}
                <div className="relative">
                  <div className="absolute inset-0 flex items-center">
                    <span className="w-full border-t" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-white dark:bg-gray-900 px-2 text-muted-foreground">
                      Or
                    </span>
                  </div>
                </div>
              </CardContent>
            </form>

            <CardFooter className="flex flex-col space-y-4">
              {/* Registration CTA */}
              <div className="w-full">
                <div className="text-center mb-3">
                  <span className="text-sm text-muted-foreground">Don't have an account?</span>
                </div>
                <Button 
                  variant="outline" 
                  className="w-full" 
                  size="lg"
                  onClick={() => router.push('/register')}
                >
                  Register Your Company
                </Button>
              </div>

              {/* Demo Credentials */}
              <div className="w-full border-t pt-4">
                <div className="text-sm font-medium text-center mb-3">
                  Try Demo Accounts
                </div>
                <div className="space-y-2">
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('admin@receiptcapture.com', 'admin123')}
                    className="w-full p-3 text-left border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                    disabled={isLoading}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-sm font-medium">Master Admin</div>
                        <div className="text-xs text-muted-foreground">admin@receiptcapture.com</div>
                      </div>
                      <Badge variant="secondary" className="text-xs">Admin</Badge>
                    </div>
                  </button>
                  
                  <button
                    type="button"
                    onClick={() => handleDemoLogin('rep@techcorp.com', 'password123')}
                    className="w-full p-3 text-left border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                    disabled={isLoading}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-sm font-medium">Company Representative</div>
                        <div className="text-xs text-muted-foreground">rep@techcorp.com</div>
                      </div>
                      <Badge variant="outline" className="text-xs">Company</Badge>
                    </div>
                  </button>
                </div>
              </div>
            </CardFooter>
          </Card>

          {/* Security notice */}
          <div className="mt-6 flex items-center justify-center gap-2 text-xs text-muted-foreground">
            <Shield className="h-4 w-4" />
            <span>Your data is secure and encrypted</span>
          </div>
        </div>
      </div>

      {/* Right side - Feature Highlights */}
      <div className="hidden lg:flex lg:flex-1 bg-gradient-to-br from-primary/10 via-primary/5 to-background items-center justify-center p-12">
        <div className="max-w-md">
          <h2 className="text-3xl font-bold mb-6">
            Streamline Your Receipt Management
          </h2>
          <div className="space-y-6">
            <div className="flex items-start gap-4">
              <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                <CheckCircle2 className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold mb-1">Instant Receipt Capture</h3>
                <p className="text-sm text-muted-foreground">
                  Capture receipts with your phone and let AI do the rest
                </p>
              </div>
            </div>
            
            <div className="flex items-start gap-4">
              <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                <CheckCircle2 className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold mb-1">Automated Processing</h3>
                <p className="text-sm text-muted-foreground">
                  Extract merchant, date, amount, and category automatically
                </p>
              </div>
            </div>
            
            <div className="flex items-start gap-4">
              <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                <CheckCircle2 className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold mb-1">Team Collaboration</h3>
                <p className="text-sm text-muted-foreground">
                  Manage your team and track all receipts in one place
                </p>
              </div>
            </div>
            
            <div className="flex items-start gap-4">
              <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                <CheckCircle2 className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold mb-1">Secure & Compliant</h3>
                <p className="text-sm text-muted-foreground">
                  Bank-level encryption and SOC 2 compliance
                </p>
              </div>
            </div>
          </div>

          <div className="mt-12 p-6 bg-white/50 dark:bg-gray-800/50 rounded-xl backdrop-blur-sm">
            <p className="text-sm italic text-muted-foreground mb-2">
              "Receipt Capture has transformed how we manage expenses. What used to take hours now takes minutes!"
            </p>
            <p className="text-sm font-semibold">Sarah Johnson</p>
            <p className="text-xs text-muted-foreground">Finance Manager, TechCorp</p>
          </div>
        </div>
      </div>
    </div>
  );
}