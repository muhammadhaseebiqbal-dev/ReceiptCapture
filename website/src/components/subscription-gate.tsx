'use client';

import { ReactNode, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { checkSubscriptionStatus, isSubscriptionActive, getSubscriptionMessage } from '@/lib/subscription-status';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Loader2, AlertCircle } from 'lucide-react';

interface SubscriptionGateProps {
  children: ReactNode;
  fallback?: ReactNode;
  requireActive?: boolean;
}

export function SubscriptionGate({ children, fallback, requireActive = true }: SubscriptionGateProps) {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [hasAccess, setHasAccess] = useState(false);
  const [subscriptionStatus, setSubscriptionStatus] = useState('');

  useEffect(() => {
    const checkAccess = async () => {
      try {
        const token = localStorage.getItem('token');
        if (!token) {
          router.push('/login');
          return;
        }

        const status = await checkSubscriptionStatus(token);
        
        if (!status) {
          router.push('/login');
          return;
        }

        const isActive = isSubscriptionActive(status.status);
        
        if (requireActive && !isActive) {
          setSubscriptionStatus(status.status);
          setHasAccess(false);
        } else {
          setHasAccess(true);
        }
      } catch (error) {
        console.error('Error checking subscription:', error);
        setHasAccess(false);
      } finally {
        setIsLoading(false);
      }
    };

    checkAccess();
  }, [router, requireActive]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-gray-50 to-white">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-primary mx-auto mb-4" />
          <p className="text-gray-600">Checking subscription status...</p>
        </div>
      </div>
    );
  }

  if (!hasAccess) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-gray-50 to-white p-4">
        <div className="max-w-md w-full">
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription className="ml-2">
              <div className="font-semibold mb-2">Subscription Required</div>
              <p className="text-sm mb-4">
                {getSubscriptionMessage(subscriptionStatus as any)}
              </p>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => window.history.back()}
                >
                  Go Back
                </Button>
                <Button
                  size="sm"
                  onClick={() => window.location.href = '/pricing'}
                >
                  View Pricing
                </Button>
              </div>
            </AlertDescription>
          </Alert>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
