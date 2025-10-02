import { User, Company, SubscriptionPlan, AppUser, Receipt } from '@/types';

// In-memory data store - replace with database later
class DataStore {
  private users: User[] = [];
  private companies: Company[] = [];
  private subscriptionPlans: SubscriptionPlan[] = [];
  private appUsers: AppUser[] = [];
  private receipts: Receipt[] = [];

  constructor() {
    this.initializeData();
  }

  private initializeData() {
    // Initialize with sample data
    this.subscriptionPlans = [
      {
        id: '1',
        name: 'Starter',
        description: 'Perfect for small teams',
        price: 29.99,
        billingCycle: 'monthly',
        maxUsers: 5,
        maxReceiptsPerMonth: 100,
        features: ['Email Support', '1GB Storage', 'Basic Analytics'],
        isActive: true,
      },
      {
        id: '2',
        name: 'Professional',
        description: 'Growing businesses',
        price: 59.99,
        billingCycle: 'monthly',
        maxUsers: 20,
        maxReceiptsPerMonth: 500,
        features: ['Priority Support', '10GB Storage', 'Advanced Analytics', 'Custom Categories'],
        isActive: true,
      },
      {
        id: '3',
        name: 'Enterprise',
        description: 'Large organizations',
        price: 149.99,
        billingCycle: 'monthly',
        maxUsers: 100,
        maxReceiptsPerMonth: 2000,
        features: ['Phone Support', 'Unlimited Storage', 'Advanced Analytics', 'API Access', 'Custom Integrations'],
        isActive: true,
      },
    ];

    // Master admin user
    this.users = [
      {
        id: 'admin-1',
        email: 'admin@receiptcapture.com',
        password: 'admin123', // In production: bcrypt hash
        name: 'Portal Master Admin',
        role: 'master_admin',
        isActive: true,
        createdAt: new Date().toISOString(),
      },
    ];

    // Sample company
    this.companies = [
      {
        id: 'company-1',
        name: 'Tech Corp Ltd',
        domain: 'techcorp.com',
        destinationEmail: 'invoices@techcorp.com',
        subscriptionPlanId: '2',
        subscriptionStatus: 'active',
        subscriptionStartDate: new Date().toISOString(),
        subscriptionEndDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        createdAt: new Date().toISOString(),
      },
    ];

    // Sample company representative
    this.users.push({
      id: 'user-1',
      email: 'rep@techcorp.com',
      password: 'password123',
      name: 'John Smith',
      role: 'company_representative',
      companyId: 'company-1',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Sample app users (staff)
    this.appUsers = [
      {
        id: 'app-user-1',
        email: 'staff1@techcorp.com',
        password: 'staff123',
        name: 'Alice Johnson',
        companyId: 'company-1',
        role: 'employee',
        isActive: true,
        createdBy: 'user-1',
        createdAt: new Date().toISOString(),
      },
      {
        id: 'app-user-2',
        email: 'manager@techcorp.com',
        password: 'mgr123',
        name: 'Bob Wilson',
        companyId: 'company-1',
        role: 'manager',
        isActive: true,
        createdBy: 'user-1',
        createdAt: new Date().toISOString(),
      },
    ];

    // Sample receipts
    this.receipts = [
      {
        id: 'receipt-1',
        userId: 'app-user-1',
        companyId: 'company-1',
        imagePath: '/uploads/receipt-1.jpg',
        merchantName: 'Office Depot',
        amount: 45.99,
        receiptDate: '2025-09-25T10:30:00Z',
        category: 'Office Supplies',
        notes: 'Printer paper and pens',
        status: 'sent',
        emailSentAt: '2025-09-25T11:00:00Z',
        createdAt: '2025-09-25T10:45:00Z',
      },
      {
        id: 'receipt-2',
        userId: 'app-user-2',
        companyId: 'company-1',
        imagePath: '/uploads/receipt-2.jpg',
        merchantName: 'Starbucks',
        amount: 12.50,
        receiptDate: '2025-09-28T08:15:00Z',
        category: 'Meals & Entertainment',
        notes: 'Client meeting coffee',
        status: 'processed',
        createdAt: '2025-09-28T08:20:00Z',
      },
      {
        id: 'receipt-3',
        userId: 'app-user-1',
        companyId: 'company-1',
        imagePath: '/uploads/receipt-3.jpg',
        merchantName: 'Shell Gas Station',
        amount: 67.88,
        receiptDate: '2025-10-01T14:22:00Z',
        category: 'Travel & Transportation',
        notes: 'Business trip fuel',
        status: 'pending',
        createdAt: '2025-10-01T14:25:00Z',
      },
      {
        id: 'receipt-4',
        userId: 'app-user-2',
        companyId: 'company-1',
        imagePath: '/uploads/receipt-4.jpg',
        merchantName: 'Best Buy',
        amount: 299.99,
        receiptDate: '2025-10-02T11:45:00Z',
        category: 'Equipment',
        notes: 'Wireless mouse and keyboard',
        status: 'pending',
        createdAt: '2025-10-02T12:00:00Z',
      },
      {
        id: 'receipt-5',
        userId: 'app-user-1',
        companyId: 'company-1',
        imagePath: '/uploads/receipt-5.jpg',
        merchantName: 'Amazon Business',
        amount: 89.95,
        receiptDate: '2025-10-02T16:30:00Z',
        category: 'Office Supplies',
        status: 'processed',
        createdAt: '2025-10-02T16:35:00Z',
      },
    ];
  }

  // Users methods
  getUsers() { return [...this.users]; }
  getUserById(id: string) { return this.users.find(u => u.id === id); }
  getUserByEmail(email: string) { return this.users.find(u => u.email === email); }
  addUser(user: User) { this.users.push(user); }
  updateUser(id: string, updates: Partial<User>) {
    const index = this.users.findIndex(u => u.id === id);
    if (index !== -1) {
      this.users[index] = { ...this.users[index], ...updates };
    }
  }

  // Companies methods
  getCompanies() { return [...this.companies]; }
  getCompanyById(id: string) { return this.companies.find(c => c.id === id); }
  addCompany(company: Company) { this.companies.push(company); }
  updateCompany(id: string, updates: Partial<Company>) {
    const index = this.companies.findIndex(c => c.id === id);
    if (index !== -1) {
      this.companies[index] = { ...this.companies[index], ...updates };
    }
  }

  // Subscription plans methods
  getSubscriptionPlans() { return [...this.subscriptionPlans]; }
  getSubscriptionPlanById(id: string) { return this.subscriptionPlans.find(p => p.id === id); }

  // App users methods
  getAppUsers() { return [...this.appUsers]; }
  getAppUsersByCompany(companyId: string) { 
    return this.appUsers.filter(u => u.companyId === companyId); 
  }
  addAppUser(user: AppUser) { this.appUsers.push(user); }
  updateAppUser(id: string, updates: Partial<AppUser>) {
    const index = this.appUsers.findIndex(u => u.id === id);
    if (index !== -1) {
      this.appUsers[index] = { ...this.appUsers[index], ...updates };
    }
  }
  deleteAppUser(id: string) {
    this.appUsers = this.appUsers.filter(u => u.id !== id);
  }

  // Receipts methods
  getReceipts() { return [...this.receipts]; }
  getReceiptsByCompany(companyId: string) {
    return this.receipts.filter(r => r.companyId === companyId);
  }
  updateReceipt(id: string, updates: Partial<Receipt>) {
    const index = this.receipts.findIndex(r => r.id === id);
    if (index !== -1) {
      this.receipts[index] = { ...this.receipts[index], ...updates };
      return this.receipts[index];
    }
    return null;
  }

  // Individual getter methods
  getUser(id: string) { return this.users.find(u => u.id === id); }
  getCompany(id: string) { return this.companies.find(c => c.id === id); }
  getSubscriptionPlan(id: string) { return this.subscriptionPlans.find(p => p.id === id); }

  // Billing history (in-memory for now)
  private billingHistory: any[] = [];
  
  getBillingHistory(companyId: string) {
    return this.billingHistory.filter(b => b.companyId === companyId);
  }
  
  addBillingHistory(entry: any) {
    this.billingHistory.push(entry);
  }
}

// Singleton instance
export const dataStore = new DataStore();