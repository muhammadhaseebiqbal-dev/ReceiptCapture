'use client';

import { ReactNode, useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import { SubscriptionGate } from '@/components/subscription-gate';

export default function DashboardLayout({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [allowInactiveAccountAccess, setAllowInactiveAccountAccess] = useState(false);

  useEffect(() => {
    try {
      const rawUser = localStorage.getItem('user');
      if (!rawUser) {
        setAllowInactiveAccountAccess(false);
        return;
      }

      const parsedUser = JSON.parse(rawUser);
      setAllowInactiveAccountAccess(parsedUser?.isActive === false);
    } catch {
      setAllowInactiveAccountAccess(false);
    }
  }, [pathname]);

  const allowWithoutActiveSubscription =
    pathname?.startsWith('/dashboard/subscription') || allowInactiveAccountAccess;

  if (allowWithoutActiveSubscription) {
    return <>{children}</>;
  }

  return <SubscriptionGate>{children}</SubscriptionGate>;
}