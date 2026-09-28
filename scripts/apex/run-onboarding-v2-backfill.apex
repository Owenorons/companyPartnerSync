// Chunk size 15, not 50: PartnerOnboardingLifecycleService.initialise()
// does ~5 SOQL + ~7 DML per application, so even 50 rows (~250 SOQL,
// ~350 DML) exceeds both per-transaction governor limits - found during a
// pre-beta bulk-safety audit.
Database.executeBatch(new PartnerOnboardingMigrationBatch(), 15);
