import { supabaseAdmin } from '@/lib/supabase-server';
import { generateToken, hashPassword, verifyPassword } from '@/lib/auth';
import { isValidEmail } from '@/lib/utils';

export interface AuthUserPayload {
  id: string;
  email: string;
  name: string;
  role: string;
  companyId: string | null;
  isActive: boolean;
}

export interface RegisterCompanyInput {
  companyName: string;
  companyDomain?: string;
  destinationEmail: string;
  representativeName: string;
  representativeEmail: string;
  representativePassword: string;
  selectedPlanId: string;
}

function mapUser(user: {
  id: string;
  email: string;
  name: string;
  role: string;
  company_id: string | null;
  is_active: boolean;
}): AuthUserPayload {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    companyId: user.company_id,
    isActive: user.is_active,
  };
}

export async function registerCompanyRepresentative(input: RegisterCompanyInput) {
  const {
    companyName,
    companyDomain,
    destinationEmail,
    representativeName,
    representativeEmail,
    representativePassword,
    selectedPlanId,
  } = input;

  if (!companyName || !destinationEmail || !representativeName || !representativeEmail || !representativePassword || !selectedPlanId) {
    return { error: 'All required fields must be provided', status: 400 };
  }

  if (!isValidEmail(representativeEmail)) {
    return { error: 'Invalid representative email format', status: 400 };
  }

  const { data: existingUser, error: existingUserError } = await supabaseAdmin
    .from('users')
    .select('id')
    .eq('email', representativeEmail.toLowerCase())
    .maybeSingle();

  if (existingUserError) {
    return { error: 'Failed to verify existing user', status: 500 };
  }

  if (existingUser) {
    return { error: 'A user with this email already exists', status: 400 };
  }

  const { data: subscriptionPlan, error: planError } = await supabaseAdmin
    .from('subscription_plans')
    .select('id, name, billing_cycle')
    .eq('id', selectedPlanId)
    .eq('is_active', true)
    .maybeSingle();

  if (planError) {
    return { error: 'Failed to verify subscription plan', status: 500 };
  }

  if (!subscriptionPlan) {
    return { error: 'Invalid subscription plan selected', status: 400 };
  }

  const now = new Date();
  const subscriptionEndDate = new Date(now);
  subscriptionEndDate.setDate(subscriptionEndDate.getDate() + 30);

  const { data: company, error: companyError } = await supabaseAdmin
    .from('companies')
    .insert({
      name: companyName,
      domain: companyDomain || null,
      destination_email: destinationEmail.toLowerCase(),
      subscription_plan_id: selectedPlanId,
      subscription_status: 'trial',
      subscription_start_date: now.toISOString(),
      subscription_end_date: subscriptionEndDate.toISOString(),
    })
    .select('id, name, destination_email, subscription_status')
    .single();

  if (companyError || !company) {
    return { error: 'Failed to create company', status: 500 };
  }

  const passwordHash = await hashPassword(representativePassword);

  const { data: user, error: userCreateError } = await supabaseAdmin
    .from('users')
    .insert({
      email: representativeEmail.toLowerCase(),
      password_hash: passwordHash,
      name: representativeName,
      role: 'company_representative',
      company_id: company.id,
      is_active: true,
    })
    .select('id, email, name, role, company_id, is_active')
    .single();

  if (userCreateError || !user) {
    return { error: 'Failed to create representative account', status: 500 };
  }

  await supabaseAdmin.from('billing_history').insert({
    company_id: company.id,
    plan_id: selectedPlanId,
    plan_name: subscriptionPlan.name,
    amount: 0,
    billing_cycle: subscriptionPlan.billing_cycle,
    status: 'paid',
    billing_date: now.toISOString(),
    next_billing_date: subscriptionEndDate.toISOString(),
    description: `30-day trial for ${subscriptionPlan.name} plan`,
  });

  const token = generateToken(user.id, user.email, user.role, user.company_id);

  return {
    success: true,
    user: mapUser(user),
    company: {
      id: company.id,
      name: company.name,
      destinationEmail: company.destination_email,
      subscriptionStatus: company.subscription_status,
    },
    token,
    tokenPayload: {
      userId: user.id,
      email: user.email,
      role: user.role,
      companyId: user.company_id,
    },
    subscriptionPlan: {
      name: subscriptionPlan.name,
      trialEndDate: subscriptionEndDate.toISOString(),
    },
  };
}

export async function loginPortalUser(email: string, password: string) {
  if (!email || !password) {
    return { error: 'Email and password are required', status: 400 };
  }

  if (!isValidEmail(email)) {
    return { error: 'Invalid email format', status: 400 };
  }

  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .select('id, email, password_hash, name, role, company_id, is_active')
    .eq('email', email.toLowerCase())
    .maybeSingle();

  if (userError || !user) {
    return { error: 'Invalid credentials', status: 401 };
  }

  const isValidPassword = await verifyPassword(password, user.password_hash);
  if (!isValidPassword) {
    return { error: 'Invalid credentials', status: 401 };
  }

  if (!user.is_active) {
    return { error: 'Account is inactive. Please contact support.', status: 403 };
  }

  if (!['company_representative', 'master_admin'].includes(user.role)) {
    return { error: 'Unauthorized account type', status: 403 };
  }

  const token = generateToken(user.id, user.email, user.role, user.company_id);

  return {
    user: mapUser(user),
    token,
    tokenPayload: {
      userId: user.id,
      email: user.email,
      role: user.role,
      companyId: user.company_id,
    },
  };
}

export async function loginStaffUser(email: string, password: string) {
  if (!email || !password) {
    return { error: 'Email and password are required', status: 400 };
  }

  if (!isValidEmail(email)) {
    return { error: 'Invalid email format', status: 400 };
  }

  const { data: user, error: userError } = await supabaseAdmin
    .from('users')
    .select('id, email, password_hash, name, role, company_id, is_active')
    .eq('email', email.toLowerCase())
    .in('role', ['manager', 'employee'])
    .maybeSingle();

  if (userError || !user) {
    return { error: 'Invalid credentials', status: 401 };
  }

  const isValidPassword = await verifyPassword(password, user.password_hash);
  if (!isValidPassword) {
    return { error: 'Invalid credentials', status: 401 };
  }

  if (!user.is_active) {
    return { error: 'Account is inactive. Please contact your company representative.', status: 403 };
  }

  const token = generateToken(user.id, user.email, user.role, user.company_id);

  return {
    user: mapUser(user),
    token,
    tokenPayload: {
      userId: user.id,
      email: user.email,
      role: user.role,
      companyId: user.company_id,
    },
  };
}