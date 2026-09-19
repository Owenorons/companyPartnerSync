System.schedule(
  'PartnerSync Lifecycle Governance Daily',
  '0 0 2 * * ?',
  new PartnerLifecycleGovernanceBatch()
);
