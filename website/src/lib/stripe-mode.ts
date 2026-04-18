// Defaults to simulated Stripe mode until explicitly disabled in env.
// Set NEXT_PUBLIC_FORCE_STRIPE_SIMULATION=false when real Stripe credentials are configured.
const simulationEnv = process.env.NEXT_PUBLIC_FORCE_STRIPE_SIMULATION;

export const FORCE_STRIPE_SIMULATION = simulationEnv == null
  ? true
  : simulationEnv.toLowerCase() !== 'false';

export const STRIPE_SIMULATION_MESSAGE =
  'Stripe payment step is running in simulated mode for development. No real charge will be made.';
