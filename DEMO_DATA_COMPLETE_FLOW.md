# 🎯 Complete Demo Data Flow - Database Setup

## Overview
The updated SQL script now includes **comprehensive demo data** that demonstrates the complete flow of the Receipt Capture system with realistic scenarios across all related tables.

---

## 📊 Demo Data Summary

### **3 Companies** with Different Scenarios

#### **1. TechCorp Demo** (Active Professional Plan)
- **Status**: Active ✅
- **Plan**: Professional ($59.99/month)
- **Subscription**: Active for 2 months with successful renewals
- **Contact**: 123 Tech Street, Silicon Valley, CA 94025
- **Website**: https://www.techcorp.com

#### **2. Marketing Inc** (Trial Starter Plan)
- **Status**: Trial 🟡
- **Plan**: Starter ($29.99/month - 14-day trial)
- **Subscription**: Day 5 of 14-day trial (9 days remaining)
- **Contact**: 456 Market Avenue, New York, NY 10001
- **Website**: https://www.marketinginc.com

#### **3. Startup LLC** (Expired Subscription)
- **Status**: Inactive 🔴
- **Plan**: Starter (expired 1 week ago)
- **Subscription**: Payment failed, subscription ended
- **Contact**: 789 Innovation Drive, Austin, TX 78701
- **Website**: https://www.startup.io

---

## 👥 Representatives (Portal Users)

### **Platform Level**
| Name | Email | Password | Role | Company | Verified Email |
|------|-------|----------|------|---------|----------------|
| Portal Master Admin | admin@receiptcapture.com | admin123 | master_admin | None | admin@receiptcapture.com |

### **TechCorp Demo**
| Name | Email | Password | Role | Primary | Verified Email | Phone |
|------|-------|----------|------|---------|----------------|-------|
| John Doe | rep@techcorp.com | password123 | primary_representative | ✅ Yes | **receipts@techcorp.com** | +1-555-0101 |
| Sarah Johnson | sarah@techcorp.com | password123 | representative | No | sarah@techcorp.com | +1-555-0102 |

**Permissions - John Doe (Primary)**:
- ✅ Add/Remove users
- ✅ View billing
- ✅ Modify subscription
- ✅ View all receipts
- ✅ Approve receipts

**Permissions - Sarah Johnson (Secondary)**:
- ✅ Add users
- ✅ View all receipts
- ✅ Approve receipts
- ❌ No billing access

### **Marketing Inc**
| Name | Email | Password | Role | Primary | Verified Email |
|------|-------|----------|------|---------|----------------|
| Mike Brown | rep@marketinginc.com | password123 | primary_representative | ✅ Yes | **receipts@marketinginc.com** |

### **Startup LLC**
| Name | Email | Password | Role | Primary | Verified Email |
|------|-------|----------|------|---------|----------------|
| Alex Chen | rep@startup.io | password123 | primary_representative | ✅ Yes | **receipts@startup.io** |

---

## 📱 Members (Mobile App Users)

### **TechCorp Demo** (3 members)

| Name | Email | Password | Employee ID | Department | Role | Phone | Receipts Uploaded |
|------|-------|----------|-------------|------------|------|-------|-------------------|
| Jane Smith | employee@techcorp.com | member123 | EMP001 | Sales | employee | +1-555-0110 | 1 |
| Bob Wilson | bob@techcorp.com | member123 | EMP002 | Marketing | manager | +1-555-0111 | 1 |
| Lisa Garcia | lisa@techcorp.com | member123 | EMP003 | Engineering | employee | +1-555-0112 | 1 |

**Created By**:
- Jane & Bob: Created by John Doe (Primary Rep)
- Lisa: Created by Sarah Johnson (Secondary Rep)

### **Marketing Inc** (1 member)

| Name | Email | Password | Employee ID | Department | Role | Receipts Uploaded |
|------|-------|----------|-------------|------------|------|-------------------|
| Tom Davis | tom@marketinginc.com | member123 | MAR001 | Creative | employee | 1 |

**Created By**: Mike Brown

---

## 💳 Transaction History (Complete Flow)

### **TechCorp Demo** - 3 Transactions
```
1. PURCHASE (2 months ago)
   └─ Professional Plan: $59.99
   └─ Period: Month 1
   └─ Status: Succeeded ✅
   └─ Payment: pi_techcorp_initial_001
   
2. RENEWAL (1 month ago)
   └─ Professional Plan: $59.99
   └─ Period: Month 2
   └─ Status: Succeeded ✅
   └─ Payment: pi_techcorp_renewal_002
   
3. RENEWAL (Current - Active)
   └─ Professional Plan: $59.99
   └─ Period: Month 3 (Current)
   └─ Status: Succeeded ✅
   └─ Payment: pi_techcorp_renewal_003
   
💰 Total Paid: $179.97 (3 months × $59.99)
```

### **Marketing Inc** - 1 Transaction
```
1. PURCHASE - TRIAL (5 days ago)
   └─ Starter Plan: $0.00 (14-day trial)
   └─ Period: Day 5 of 14
   └─ Status: Succeeded ✅
   └─ Note: 9 days remaining
```

### **Startup LLC** - 3 Transactions
```
1. PURCHASE (3 months ago)
   └─ Starter Plan: $29.99
   └─ Period: Month 1
   └─ Status: Succeeded ✅
   └─ Payment: pi_startup_initial_001
   
2. RENEWAL (2 months ago)
   └─ Starter Plan: $29.99
   └─ Period: Month 2
   └─ Status: Succeeded ✅
   └─ Payment: pi_startup_renewal_002
   
3. RENEWAL - FAILED (1 month ago)
   └─ Starter Plan: $29.99
   └─ Period: Would be Month 3
   └─ Status: Failed ❌
   └─ Payment: pi_startup_renewal_003_failed
   └─ Note: Card declined - Subscription expired
   
💰 Total Paid: $59.98 (2 months × $29.99)
🔴 Subscription Status: INACTIVE
```

---

## 🧾 Receipts (Complete Flow)

### **TechCorp Demo** - 3 Receipts

#### **Receipt #1** - Office Supplies (Jane Smith)
```
📝 Details:
   Merchant: Office Depot
   Location: 123 Main St, San Jose, CA
   Amount: $45.99
   Tax: $3.68
   Date: 5 days ago
   Category: Office Supplies > Stationery
   Payment: Credit Card
   Notes: "Purchased pens and notebooks for team"

📊 Processing:
   Status: SENT ✅
   OCR Confidence: 95.5%
   
📧 Email Forwarding:
   Sent To: receipts@techcorp.com
   Sent At: 5 minutes after upload
   Email Status: Sent ✅
```

#### **Receipt #2** - Business Lunch (Bob Wilson)
```
📝 Details:
   Merchant: The Italian Restaurant
   Location: 456 Food Ave, Palo Alto, CA
   Amount: $125.50
   Tax: $10.04
   Tip: $22.00
   Total: $157.54
   Date: 3 days ago
   Category: Food > Client Entertainment
   Payment: Corporate Card
   Notes: "Client lunch meeting"

📊 Processing:
   Status: SENT ✅
   OCR Confidence: 92.3%
   
📧 Email Forwarding:
   Sent To: receipts@techcorp.com
   Sent At: 10 minutes after upload
   Email Status: Sent ✅
```

#### **Receipt #3** - Transportation (Lisa Garcia)
```
📝 Details:
   Merchant: Uber
   Amount: $32.75
   Date: 1 day ago
   Category: Travel > Transportation
   Payment: Personal Card
   Notes: "Uber to client office for meeting"

📊 Processing:
   Status: SENT ✅
   OCR Confidence: 98.7%
   
📧 Email Forwarding:
   Sent To: receipts@techcorp.com
   Sent At: 2 minutes after upload
   Email Status: Sent ✅
```

**📬 All 3 receipts forwarded to: receipts@techcorp.com**

### **Marketing Inc** - 1 Receipt

#### **Receipt #1** - Printing Services (Tom Davis)
```
📝 Details:
   Merchant: FedEx Print & Ship
   Location: 789 Print St, New York, NY
   Amount: $156.00
   Tax: $12.48
   Date: 2 days ago
   Category: Office Supplies > Printing
   Payment: Credit Card
   Notes: "Marketing brochures for campaign"

📊 Processing:
   Status: SENT ✅
   OCR Confidence: 94.2%
   
📧 Email Forwarding:
   Sent To: receipts@marketinginc.com
   Sent At: 3 minutes after upload
   Email Status: Sent ✅
```

---

## 📈 Usage Statistics

### **TechCorp Demo**

#### **Current Month** (Ongoing)
```
📅 Period: January 2025
📊 Metrics:
   Receipts Uploaded: 3
   Receipts Processed: 3
   Receipts Sent: 3
   Active Members: 3 / 3
   Storage Used: 1.2 MB
   API Calls: 45
   
✅ Status: Within limits (Professional Plan: 500 receipts/month, 20 users max)
```

#### **Previous Month** (Calculated)
```
📅 Period: December 2024
📊 Metrics:
   Receipts Uploaded: 28
   Receipts Processed: 28
   Receipts Sent: 28
   Active Members: 3 / 3
   Storage Used: 8.5 MB
   API Calls: 112
   
✅ Status: Within limits
```

### **Marketing Inc**

#### **Current Month** (Trial Period)
```
📅 Period: January 2025
📊 Metrics:
   Receipts Uploaded: 1
   Receipts Processed: 1
   Receipts Sent: 1
   Active Members: 1 / 1
   Storage Used: 0.3 MB
   API Calls: 8
   
✅ Status: Within limits (Starter Plan: 100 receipts/month, 5 users max)
```

---

## 🔄 Complete Data Flow Example

### **Scenario: Jane Smith uploads a receipt**

```
1. 👤 MEMBER (Jane Smith)
   └─ Opens mobile app
   └─ Company: TechCorp Demo
   └─ Employee ID: EMP001
   └─ Department: Sales

2. 📸 UPLOAD RECEIPT
   └─ Scans receipt with phone camera
   └─ Merchant: Office Depot
   └─ Amount: $45.99
   
3. 🤖 OCR PROCESSING
   └─ Extract merchant name ✅
   └─ Extract amount ✅
   └─ Extract date ✅
   └─ Confidence: 95.5%
   
4. 💾 SAVE TO DATABASE
   └─ Table: receipts
   └─ member_id: Jane's UUID
   └─ company_id: TechCorp UUID
   └─ status: 'processed'
   
5. 📧 EMAIL FORWARDING
   └─ Look up: TechCorp's primary representative
   └─ Find: John Doe (is_primary = true)
   └─ Get: verified_email = receipts@techcorp.com
   └─ Send email with receipt details
   └─ Update: email_sent_to = receipts@techcorp.com
   └─ Update: email_status = 'sent'
   
6. 📊 UPDATE STATISTICS
   └─ members.total_receipts_uploaded++  (Jane: 0 → 1)
   └─ usage_statistics.receipts_uploaded++  (TechCorp: 2 → 3)
   └─ usage_statistics.receipts_sent++  (TechCorp: 2 → 3)

7. ✅ COMPLETE
   └─ Receipt stored in database
   └─ Email sent to receipts@techcorp.com
   └─ Statistics updated
   └─ Ready for next receipt
```

---

## 🎯 Key Relationships Demonstrated

### **1. Company → Representative → Verified Email**
```
TechCorp Demo
  └─ Primary Rep: John Doe
      └─ verified_email: receipts@techcorp.com
          └─ ALL receipts sent here ✅
```

### **2. Company → Members → Receipts**
```
TechCorp Demo
  ├─ Member: Jane (EMP001 - Sales)
  │   └─ Receipt: Office Depot ($45.99)
  ├─ Member: Bob (EMP002 - Marketing)
  │   └─ Receipt: Italian Restaurant ($125.50)
  └─ Member: Lisa (EMP003 - Engineering)
      └─ Receipt: Uber ($32.75)
```

### **3. Company → Transaction History**
```
TechCorp Demo
  ├─ Transaction 1: Purchase (2 months ago) ✅
  ├─ Transaction 2: Renewal (1 month ago) ✅
  └─ Transaction 3: Renewal (Current) ✅
  
Marketing Inc
  └─ Transaction 1: Trial Start (5 days ago) ✅
  
Startup LLC
  ├─ Transaction 1: Purchase (3 months ago) ✅
  ├─ Transaction 2: Renewal (2 months ago) ✅
  └─ Transaction 3: Failed Renewal (1 month ago) ❌
```

### **4. Company → Usage Statistics**
```
TechCorp Demo
  ├─ Current Month: 3 receipts, 3 active users
  └─ Previous Month: 28 receipts, 3 active users
  
Marketing Inc
  └─ Current Month: 1 receipt, 1 active user
```

---

## 🧪 Testing Scenarios

### **Scenario 1: Active Company (TechCorp)**
```
✅ Login as: rep@techcorp.com / password123
✅ View: 3 members, 3 receipts
✅ Check: All receipts sent to receipts@techcorp.com
✅ Verify: Transaction history shows 3 successful payments
✅ Confirm: Usage within Professional plan limits
```

### **Scenario 2: Trial Company (Marketing Inc)**
```
✅ Login as: rep@marketinginc.com / password123
✅ View: 1 member, 1 receipt
✅ Check: Trial period with 9 days remaining
✅ Verify: $0.00 charged for trial
✅ Test: Member tom@marketinginc.com can upload receipts
```

### **Scenario 3: Expired Company (Startup LLC)**
```
✅ Login as: rep@startup.io / password123
✅ View: Subscription expired 1 week ago
✅ Check: No active members
✅ Verify: Last payment failed
✅ See: Prompt to renew subscription
```

### **Scenario 4: Master Admin**
```
✅ Login as: admin@receiptcapture.com / admin123
✅ View: All 3 companies
✅ Manage: Subscription plans
✅ Access: All transaction history
✅ See: Platform-wide statistics
```

---

## 📊 Database Verification Queries

After running the SQL script, you can verify the data:

```sql
-- Count records in each table
SELECT 'Subscription Plans' as table_name, COUNT(*) FROM subscription_plans
UNION ALL SELECT 'Companies', COUNT(*) FROM registered_companies
UNION ALL SELECT 'Representatives', COUNT(*) FROM representatives
UNION ALL SELECT 'Members', COUNT(*) FROM members
UNION ALL SELECT 'Receipts', COUNT(*) FROM receipts
UNION ALL SELECT 'Transactions', COUNT(*) FROM transaction_history
UNION ALL SELECT 'Usage Stats', COUNT(*) FROM usage_statistics;

-- Expected Results:
-- Subscription Plans: 3
-- Companies: 3
-- Representatives: 5
-- Members: 4
-- Receipts: 4
-- Transactions: 7
-- Usage Stats: 3
```

---

## 🎉 Summary

The demo data now includes:

✅ **3 Subscription Plans** (Starter, Professional, Enterprise)
✅ **3 Companies** (Active, Trial, Expired scenarios)
✅ **5 Representatives** (1 platform admin + 4 company reps)
✅ **4 Members** (Mobile app users across companies)
✅ **7 Transactions** (Purchases, renewals, failed payments)
✅ **4 Receipts** (With complete OCR data and email forwarding)
✅ **3 Usage Statistics** (Monthly tracking for active companies)

**All tables are interconnected** with proper foreign keys and realistic data flow! 🚀

---

**Last Updated**: October 19, 2025
**Schema Version**: 2.0
**Demo Data**: Complete Flow ✅
