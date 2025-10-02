'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  CheckCircle, 
  Smartphone, 
  Mail, 
  Settings, 
  Users, 
  Download,
  ArrowRight,
  Calendar
} from 'lucide-react';

export default function RegistrationSuccessPage() {
  const router = useRouter();
  const [countdown, setCountdown] = useState(10);

  useEffect(() => {
    const timer = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          router.push('/login');
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [router]);

  const nextSteps = [
    {
      icon: <Mail className="h-5 w-5" />,
      title: 'Check Your Email',
      description: 'Verify your email address to activate your account',
      badge: 'Step 1'
    },
    {
      icon: <Smartphone className="h-5 w-5" />,
      title: 'Download Mobile App',
      description: 'Install the Receipt Capture app on your team\'s devices',
      badge: 'Step 2'
    },
    {
      icon: <Users className="h-5 w-5" />,
      title: 'Add Staff Members',
      description: 'Create accounts for your team members through the web portal',
      badge: 'Step 3'
    },
    {
      icon: <Settings className="h-5 w-5" />,
      title: 'Configure Settings',
      description: 'Set up your company preferences and receipt forwarding',
      badge: 'Step 4'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl w-full space-y-8">
        {/* Success Header */}
        <div className="text-center">
          <div className="flex justify-center mb-6">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
              <CheckCircle className="h-10 w-10 text-green-600" />
            </div>
          </div>
          <h2 className="text-3xl font-bold text-gray-900 mb-2">
            Registration Successful!
          </h2>
          <p className="text-lg text-gray-600">
            Welcome to Receipt Capture! Your company account has been created.
          </p>
        </div>

        {/* Trial Information */}
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-semibold text-blue-900">30-Day Free Trial Started</h3>
                <p className="text-blue-700">
                  Your trial period begins now. No payment required until your trial expires.
                </p>
              </div>
              <Badge className="bg-blue-600 text-white">
                <Calendar className="h-4 w-4 mr-1" />
                30 Days
              </Badge>
            </div>
          </CardContent>
        </Card>

        {/* Next Steps */}
        <Card>
          <CardHeader>
            <CardTitle>Getting Started - Next Steps</CardTitle>
            <CardDescription>
              Follow these steps to set up your Receipt Capture system
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {nextSteps.map((step, index) => (
              <div key={index} className="flex items-start space-x-4 p-4 border border-gray-200 rounded-lg">
                <div className="flex-shrink-0">
                  <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600">
                    {step.icon}
                  </div>
                </div>
                <div className="flex-1">
                  <div className="flex items-center space-x-2 mb-1">
                    <h4 className="font-medium text-gray-900">{step.title}</h4>
                    <Badge variant="outline" className="text-xs">{step.badge}</Badge>
                  </div>
                  <p className="text-sm text-gray-600">{step.description}</p>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Mobile App Download */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Download className="h-5 w-5 mr-2" />
              Download Receipt Capture App
            </CardTitle>
            <CardDescription>
              Your team will use the mobile app to capture and upload receipts
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="border border-gray-200 rounded-lg p-4 text-center">
                <div className="w-12 h-12 bg-gray-100 rounded-lg mx-auto mb-3 flex items-center justify-center">
                  <Smartphone className="h-6 w-6 text-gray-600" />
                </div>
                <h4 className="font-medium mb-2">Android</h4>
                <Button size="sm" className="w-full" disabled>
                  Coming Soon
                </Button>
              </div>
              <div className="border border-gray-200 rounded-lg p-4 text-center">
                <div className="w-12 h-12 bg-gray-100 rounded-lg mx-auto mb-3 flex items-center justify-center">
                  <Smartphone className="h-6 w-6 text-gray-600" />
                </div>
                <h4 className="font-medium mb-2">iOS</h4>
                <Button size="sm" className="w-full" disabled>
                  Coming Soon
                </Button>
              </div>
            </div>
            <p className="text-xs text-gray-500 mt-4 text-center">
              Mobile apps will be available once development is complete. 
              For now, you can access all features through this web portal.
            </p>
          </CardContent>
        </Card>

        {/* Action Buttons */}
        <div className="space-y-4">
          <Button 
            className="w-full" 
            onClick={() => router.push('/login')}
            size="lg"
          >
            Continue to Dashboard
            <ArrowRight className="h-4 w-4 ml-2" />
          </Button>
          
          <div className="text-center text-sm text-gray-600">
            Automatically redirecting in {countdown} seconds...
          </div>
        </div>

        {/* Support Information */}
        <Card className="bg-gray-50">
          <CardContent className="p-4">
            <h4 className="font-medium text-gray-900 mb-2">Need Help?</h4>
            <p className="text-sm text-gray-600">
              If you have any questions about setting up your account or using Receipt Capture, 
              please contact our support team at{' '}
              <a href="mailto:support@receiptcapture.com" className="text-blue-600 hover:underline">
                support@receiptcapture.com
              </a>
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}