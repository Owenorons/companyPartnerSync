# Salesforce Code Analyzer and PMD review

PartnerSync uses the supported Salesforce Code Analyzer v5 configuration file
at `code-analyzer.yml` and the built-in PMD engine. The CI security gate selects
the PMD `Security` and `AppExchange` tags.

## Suppression policy

Suppressions are allowed only when the finding has been manually reviewed and
the Apex class carries an explicit PMD rule annotation. CI permits zero
unsuppressed high or moderate findings, so a new finding fails analysis.

- `CustomerAccountSelector` applies object checks and user-mode SOQL in
  production; PMD reports its isolated test-mode query branches.
- `AIInsightGeneratorService` applies create checks and strips inaccessible
  fields before insert.
- `PartnerHealthScoringService` reads package custom metadata, which isn't a
  subscriber data CRUD boundary.
- `PartnerDocumentService` and `PartnerOnboardingLifecycleService` are
  controlled system-mode orchestration invoked behind authorised lifecycle
  services. Their system-mode behavior is intentional so package automation
  doesn't depend on the scheduling user's mutable field permissions.
- `PartnerProvisioningReconciler` is unattended recovery automation over
  package-owned state.
- `PartnerShareService` checks the record-share management authority and strips
  inaccessible registry fields before DML. Salesforce share-row creation is
  necessarily system orchestration.
- `PartnerSyncSetupController` requires the internal administrator permission
  set before reading setup and scheduling state.
- `DealValidationEngine` builds identifiers only from installed schema and a
  constant package metadata suffix; no user value is concatenated into SOQL.

The PMD `ProtectSensitiveData` metadata-name heuristic is disabled because it
reports ordinary fields such as `Assignment_Status__c`, `Rule_Key__c`, and
`Max_Tokens__c`. PartnerSync stores authentication material only in Salesforce
Named Credentials. The unused `Webhook_Endpoint__mdt.Secret_Key__c` field was
removed after this review so the rule override doesn't conceal a real secret
storage path.
