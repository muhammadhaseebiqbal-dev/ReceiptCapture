// Subscription status utilities

export type SubscriptionStatus = 'active' | 'inactive' | 'trial' | 'suspended' | 'expired';

export interface SubscriptionInfo {
  status: SubscriptionStatus;
  planId: string;
  planName: string;
  endDate: string | null;
  isActive: boolean;
}

export async function checkSubscriptionStatus(token: string): Promise<SubscriptionInfo | null> {
  try {
    const response = await fetch('/api/company/subscription-status', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (!response.ok) {
      if (response.status === 401) {
        // Not authenticated
        return null;
      }
      throw new Error('Failed to check subscription status');
    }

    return await response.json();
  } catch (error) {
    console.error('Error checking subscription status:', error);
    return null;
  }
}

export function isSubscriptionActive(status: SubscriptionStatus): boolean {
  return status === 'active' || status === 'trial';
}

export function getSubscriptionMessage(status: SubscriptionStatus): string {
  switch (status) {
    case 'active':
      return 'Your subscription is active';
    case 'trial':
      return 'You are on a free trial';
    case 'inactive':
      return 'Your subscription is inactive. Please upgrade.';
    case 'expired':
      return 'Your subscription has expired. Please renew.';
    case 'suspended':
      return 'Your subscription has been suspended. Please contact support.';
    default:
      return 'Unknown subscription status';
  }
}
