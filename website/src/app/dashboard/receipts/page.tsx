'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Receipt } from '@/types';
import { formatCurrency, formatDate } from '@/lib/utils';
import { 
  ArrowLeft,
  Receipt as ReceiptIcon,
  Search,
  Filter,
  Eye,
  Mail,
  CheckCircle,
  Clock,
  Send,
  AlertCircle
} from 'lucide-react';

interface ReceiptWithUser extends Receipt {
  userName: string;
  userEmail: string;
}

interface ReceiptsData {
  receipts: ReceiptWithUser[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
  stats: {
    total: number;
    pending: number;
    processed: number;
    sent: number;
  };
}

export default function ReceiptsPage() {
  const router = useRouter();
  const [data, setData] = useState<ReceiptsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

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

    loadReceipts(token);
  }, [router]);

  const loadReceipts = async (token: string) => {
    try {
      const response = await fetch('/api/receipts', {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error('Failed to load receipts');
      }

      const result = await response.json();
      setData(result);

    } catch (error) {
      console.error('Failed to load receipts:', error);
      setError('Failed to load receipts');
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return (
          <Badge className="bg-yellow-100 text-yellow-800">
            <Clock className="h-3 w-3 mr-1" />
            Pending
          </Badge>
        );
      case 'processed':
        return (
          <Badge className="bg-blue-100 text-blue-800">
            <CheckCircle className="h-3 w-3 mr-1" />
            Processed
          </Badge>
        );
      case 'sent':
        return (
          <Badge className="bg-green-100 text-green-800">
            <Send className="h-3 w-3 mr-1" />
            Sent
          </Badge>
        );
      default:
        return <Badge>{status}</Badge>;
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
          <h1 className="text-2xl font-bold text-gray-900">Failed to load receipts</h1>
          <Button onClick={() => router.push('/dashboard')} className="mt-4">
            Return to Dashboard
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
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
                <h1 className="text-2xl font-bold text-gray-900">Receipt Management</h1>
                <p className="text-sm text-gray-600">View and manage company receipts</p>
              </div>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {error && (
          <Alert variant="destructive" className="mb-4">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center">
                <ReceiptIcon className="h-8 w-8 text-gray-600 mr-3" />
                <div>
                  <div className="text-2xl font-bold">{data.stats.total}</div>
                  <div className="text-xs text-muted-foreground">Total Receipts</div>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center">
                <Clock className="h-8 w-8 text-yellow-600 mr-3" />
                <div>
                  <div className="text-2xl font-bold">{data.stats.pending}</div>
                  <div className="text-xs text-muted-foreground">Pending</div>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center">
                <CheckCircle className="h-8 w-8 text-blue-600 mr-3" />
                <div>
                  <div className="text-2xl font-bold">{data.stats.processed}</div>
                  <div className="text-xs text-muted-foreground">Processed</div>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center">
                <Send className="h-8 w-8 text-green-600 mr-3" />
                <div>
                  <div className="text-2xl font-bold">{data.stats.sent}</div>
                  <div className="text-xs text-muted-foreground">Sent</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Receipts List */}
        <Card>
          <CardHeader>
            <CardTitle>Receipts</CardTitle>
            <CardDescription>
              Showing {data.receipts.length} of {data.pagination.total} receipts
            </CardDescription>
          </CardHeader>
          <CardContent>
            {data.receipts.length > 0 ? (
              <div className="space-y-4">
                {data.receipts.map((receipt) => (
                  <div key={receipt.id} className="border rounded-lg p-4 hover:shadow-sm transition-shadow">
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <div className="font-medium text-lg">{receipt.merchantName || 'Unknown Merchant'}</div>
                          {getStatusBadge(receipt.status)}
                        </div>
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                          <div>
                            <span className="text-muted-foreground">Amount:</span>
                            <div className="font-semibold">
                              {receipt.amount ? formatCurrency(receipt.amount) : 'N/A'}
                            </div>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Date:</span>
                            <div>{formatDate(receipt.receiptDate || receipt.createdAt)}</div>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Category:</span>
                            <div>{receipt.category || 'Uncategorized'}</div>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Staff:</span>
                            <div>{receipt.userName}</div>
                          </div>
                        </div>
                        {receipt.notes && (
                          <div className="mt-2 text-sm text-muted-foreground">
                            <strong>Notes:</strong> {receipt.notes}
                          </div>
                        )}
                        {receipt.emailSentAt && (
                          <div className="mt-2 text-sm text-green-600">
                            <Mail className="h-4 w-4 inline mr-1" />
                            Email sent: {formatDate(receipt.emailSentAt)}
                          </div>
                        )}
                      </div>
                      <div className="flex space-x-2">
                        <Button size="sm" variant="outline">
                          <Eye className="h-4 w-4 mr-1" />
                          View
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <ReceiptIcon className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No receipts found</h3>
                <p className="text-muted-foreground">
                  Receipts uploaded by your staff will appear here.
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  );
}