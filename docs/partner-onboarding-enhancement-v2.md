# Partner Onboarding Enhancement v2

## Decision

PartnerSync will retain `Partner_Application__c` as the public registration and
initial qualification record, but approval of that record will no longer imply
that the partner is operationally active. Business qualification, evidence,
due diligence, approval, contracting, Salesforce enablement, access provisioning,
readiness and activation are independent, auditable gates.

The supported baseline remains:

> Approve the business relationship → execute agreements → establish Account and
> Contacts → an authorised administrator enables the Account as a Salesforce
> Partner → retry controlled provisioning → complete readiness → activate.

PartnerSync must distinguish the custom business classification
`Account.Is_Partner__c` from Salesforce platform enablement `Account.IsPartner`.
The former never proves that a Partner Community-style user can be created.

## Enterprise lifecycle

### 1. Registration and identity verification

A prospective partner submits `Partner_Application__c` through the public LWR
site without consuming an external-user licence. PartnerSync captures legal and
trading identity, registration and tax identifiers, addresses, corporate domain,
contacts, requested partner type/tier, territories, capabilities and versioned
consent. Duplicate, identity, email-domain and basic eligibility checks run at
submission. The initial state is `Submitted`, never `Approved`.

### 2. Triage and qualification

Partner Operations assesses strategic fit and programme capacity. Outcomes are
`Qualified`, `More Information Required`, `Not Qualified`, `Duplicate or Existing
Partner`, and `Withdrawn`. A calculated score supports the reviewer but cannot
make the governed decision by itself.

### 3. Document requirement determination

PartnerSync creates a provisional requirement plan from country, jurisdiction,
partner type, requested tier, products, territories, regulatory exposure,
security/data access, financial requirements and risk classification. Each
requirement is mandatory, conditional or optional; identifies its gate; states
whether it blocks progression; defines expiry/renewal; and declares whether a
waiver is permitted.

A review officer confirms the generated plan and can add authorised requirements,
change applicability or deadlines, and request clarification. Requested tier is
an input to the plan, not a promise of the tier ultimately awarded.

### 4. Secure document submission

The applicant receives either a time-limited verified upload link, an authenticated
pre-onboarding workspace, or an appropriately licensed external identity. A public
anonymous endpoint must not expose sensitive evidence.

Salesforce Files stores binaries. `Partner_Document__c` stores classification,
requirement, submitter, version, effective/expiry dates, confidentiality and the
`ContentDocumentId`. Upload commands are idempotent and enforce file type, size,
malware-scanning status and ownership.

### 5. Document verification

An internal reviewer accepts, rejects or requests replacement of each submitted
version. `Partner_Document_Review__c` preserves every decision, finding, reviewer,
timestamp and reason. Replaced versions are superseded, not deleted. Document
states are:

`Required → Awaiting Submission → Submitted → Under Review → Accepted | Rejected |
Replacement Required → Superseded | Expired`.

Document authenticity/completeness and the compliance meaning of its contents are
separate decisions.

### 6. Due diligence and compliance

An assessment plan coordinates corporate-registration, tax, sanctions,
beneficial-ownership, anti-bribery, conflicts, credit, insurance, security,
privacy and regulatory checks. Every check has an owner, status, due date,
evidence, outcome, expiry, reviewer and decision time. Findings are durable.
Expired or failed mandatory checks block the relevant gate unless a valid,
authorised exception explicitly releases it.

### 7. Multi-dimensional approval

`Partner_Approval_Plan__c` contains independent business, compliance, legal,
security/privacy, finance and programme steps. A step decision updates the plan;
it does not prematurely set the application to final approval. Plan outcomes are
`Conditionally Approved`, `Approved for Contracting`, `Rejected`, `More Information
Required`, and `Approval Expired`.

The assessor, approver and activation operator must be separable. Critical
waivers and final approval require restricted custom permissions assigned outside
ordinary reviewer groups.

### 8. Agreement preparation and legal review

PartnerSync selects a versioned template, merges approved data, identifies legal
entities and authorised signatories, routes internal legal/commercial review,
records negotiated deviations, locks the execution version and releases it for
signature. Agreements can include programme, NDA, DPA, security, territory,
pricing, support, conduct and policy instruments.

### 9. Electronic execution

PartnerSync orchestrates DocuSign, Adobe Acrobat Sign or another approved provider
through Named Credentials and External Credentials. It does not implement a
signature engine. Provider webhooks require signature validation, idempotent event
processing, correlation, replay protection and durable failure handling.

Agreement states are independent of application approval:

`Draft → Internal Review → Negotiation → Approved for Signature → Sent → Viewed →
Partially Signed → Executed → Effective → Expired | Terminated`.

Executed and Effective remain distinct. The executed document, completion
certificate and immutable provider audit evidence are retained.

### 10. Account and relationship establishment

After required agreements are executed, or an authorised exception exists,
PartnerSync matches or creates Accounts and Contacts and establishes the programme
relationship, tier, territory, ownership, hierarchy, contract and renewal dates.
This establishes the business relationship but does not create external access.

### 11. Salesforce partner enablement

PartnerSync verifies `Account.IsPartner`, licence availability, compatible profile,
external roles, permission sets/groups, active Experience Cloud site, eligible
Account/Contact, unique identity and configuration diagnostics. The default flow is
manual: show `Partner Enablement Required`, let an authorised administrator use
Manage External Account, recheck `Account.IsPartner`, then allow retry.

### 12. Access requests and provisioning

User provisioning begins from `Partner_Access_Request__c`, not directly from
application approval. Each request has a person/partner context, requested access
bundle, approver, expiry and idempotency key. Provisioning assigns thin profiles
and persona permission-set groups, persists every attempt and classifies failures
as durable outcomes such as:

```text
success: false
outcome: ProvisioningPending
reasonCode: ACCOUNT_NOT_PARTNER_ENABLED
retryAllowed: true
attemptPersisted: true
```

Retries have a maximum and escalation path; withdrawn/revoked requests disable
access immediately.

### 13. Readiness and activation

Provisioning does not activate the partner. Readiness evaluates first administrator
login, mandatory training, policy acceptance, completed profile, products and
territories, deal/MDF training, support contacts, account-sharing test, internal
owner and approved launch checklist. Only a persisted `Ready` result permits the
partner lifecycle to become `Active`.

### 14. Hypercare and ongoing governance

For the first 30–90 days, monitor engagement, training, provisioning failures,
initial transactions, cases, channel-manager check-ins and time to first value.
Thereafter schedule recertification, agreement/insurance renewal, permission
review, tier reassessment, contact validation, dormancy detection and compliance
rescreening.

### 15. Suspension and offboarding

Lifecycle states include `Suspended`, `Under Investigation`, `Termination Pending`,
`Terminated`, and `Archived`. Offboarding freezes new deal/MDF submissions,
disables external users, removes assignments, revokes managed sharing and
credentials, reassigns work, resolves protected deals/opportunities, preserves
history and records termination authority plus evidence of access removal.

## Target data model

| Record                            | Responsibility                                       |
| --------------------------------- | ---------------------------------------------------- |
| `Partner_Onboarding__c`           | Master onboarding case and gate summary              |
| `Partner_Onboarding_Task__c`      | Checklist, SLA and assigned work                     |
| `Partner_Assessment__c`           | Qualification, due-diligence or readiness assessment |
| `Partner_Assessment_Finding__c`   | Durable assessment finding                           |
| `Partner_Approval_Plan__c`        | Versioned multi-dimensional approval plan            |
| `Partner_Approval_Step__c`        | Individual governed approval                         |
| `Partner_Document_Requirement__c` | Required evidence and gate policy                    |
| `Partner_Document__c`             | Submitted file-control metadata and version          |
| `Partner_Document_Review__c`      | Immutable verification decision                      |
| `Partner_Agreement__c`            | Agreement preparation, execution and effective state |
| `Partner_Agreement_Signatory__c`  | Signing party, order and outcome                     |
| `Partner_Consent__c`              | Versioned declaration and policy acceptance          |
| `Partner_Exception__c`            | Waiver, authority, conditions and expiry             |
| `Partner_Relationship__c`         | Account-to-programme relationship and lifecycle      |
| `Partner_Access_Request__c`       | Approved person/access-bundle request                |
| `Partner_Provisioning_Attempt__c` | Durable technical attempt and outcome                |
| `Partner_Training_Assignment__c`  | Training/readiness evidence                          |
| `Partner_Lifecycle_Event__c`      | Append-only business audit timeline                  |

Lookup relationships are preferred where independent ownership, package install
flexibility or retention is required. Files remain in Salesforce Files. Sensitive
tax, bank, ownership, identity and legal data should use Shield Platform Encryption
where available.

## Activation gate contract

Activation succeeds only when all of the following are true:

```text
qualification complete
AND every mandatory document accepted and current
AND every blocking finding resolved or validly waived
AND every required approval step complete
AND every required agreement executed and effective
AND no expired or revoked gate-releasing exception
AND partner relationship established
AND Account.IsPartner = true
AND approved access request provisioned
AND readiness assessment = Ready
```

The evaluator returns and persists individual gate results. It must not merely
throw an exception or collapse all concerns into `Application_Status__c`.

## Security model

- Applicants receive access only to their verified pre-onboarding workspace and
  explicitly shared requirements/documents.
- Document reviewers, compliance, legal, finance and security access are separate
  capability permission sets composed into personas.
- Agreement execution, exception approval, partner enablement, user provisioning
  and final activation are separate custom permissions.
- Sensitive document metadata is absent from general partner and channel-user FLS.
- Record access uses explicit participant sharing, queues and controlled Apex DTOs;
  packaging does not change subscriber OWD.
- Completed reviews, consent, agreement events and exception decisions are locked
  or append-only.

## Reconciliation with the current implementation

The current implementation already provides public application submission,
duplicate prevention, review, Account/Contact matching, durable asynchronous user
provisioning, reconciliation and an explicit standard `Account.IsPartner` check.
These capabilities are retained.

`PartnerOnboardingService` must evolve from a single approve/reject coordinator
into the qualification and onboarding-case entry point. `PartnerUserProvisioningService`
remains the technical provisioning boundary, but will accept only an approved
`Partner_Access_Request__c` after the activation evaluator confirms contracting
and enablement prerequisites.

## Delivery sequence

1. **Foundation:** onboarding case, tasks, lifecycle events, idempotent commands,
   SLA/escalation and migration of existing applications.
2. **Evidence:** requirement rules, secure applicant workspace, document metadata,
   review history, expiry governance and partner-safe sharing.
3. **Risk and approval:** assessments/findings, approval plan/steps, exceptions,
   segregation-of-duties custom permissions and work queues.
4. **Contracting:** agreements/signatories, provider abstraction, secure webhooks,
   reconciliation and executed-evidence retention.
5. **Enablement and access:** relationship, diagnostics, access requests, durable
   provisioning attempts and permission-set-group bundles.
6. **Readiness and lifecycle:** readiness evaluator, activation, hypercare,
   recertification, suspension and offboarding orchestration.

Each slice must ship its objects, fields, CRUD/FLS, custom permissions, permission
set groups, sharing behavior, services, tests, operational diagnostics and migration
plan together. Existing approved or provisioned applications must be classified and
migrated explicitly; they must not silently bypass the new activation gates.
