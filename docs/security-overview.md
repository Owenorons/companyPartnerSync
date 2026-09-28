# PartnerSync Security Overview

A markdown reduction of `architecture-design-and-enhancement.md` §45.65's "Security_Overview.pdf" ask — a description of the real mechanisms already in this codebase, not an aspirational security program. Written for whoever needs to evaluate this package's security posture (a customer's security reviewer, or a future AppExchange Security Review submission).

## Architecture

PartnerSync is a 2GP managed package. Every business-record write goes through an application/command service (`classes/deals/`, `classes/approvals/`, `classes/customersuccess/`, etc.) — controllers and LWCs never issue raw DML against lifecycle-status fields directly. See `docs/sprint45-architecture-reconciliation.md` for the audit confirming this holds across the whole codebase.

## Authentication

PartnerSync relies entirely on the subscriber org's own Salesforce authentication (internal users, Experience Cloud partner users). It does not implement its own authentication layer, session handling, or credential store for end users.

## Authorization

Layered, matching `architecture-design-and-enhancement.md` §45.26's model:

- **Permission Sets** — technical capability (object/field access).
- **Custom Permissions**, checked via `PermissionService`/`PartnerPermissionService`/`FeatureManagement.checkPermission()` — business authority to perform an action (e.g. `PartnerSync_Approve_Deal`, `PartnerSync_View_Executive_Analytics`).
- **`PartnerAccessService`** — the internal-vs-external-user boundary (`isInternalUser()`/`assertInternalUser()`) and the current partner's own account (`getCurrentPartnerAccountId()`).
- **`PartnerRecordAccessService`** — per-record ownership checks for partner-facing reads (e.g. `assertPartnerAccessToDeal()`), enforced at the application-service layer, not relied on from raw sharing rules alone.
- **Command authorization** — lifecycle actions (approve/reject/extend/expire) are performed through command services, never direct field writes from a controller.

None of these substitute for another; see `PartnerCrossIsolationSecurityTest.cls` (Sprint 45) for runnable proof that Partner A cannot read Partner B's deals, renewals, or reach internal-only revenue-dispute data.

## Sharing

PartnerSync does not modify the subscriber org's organization-wide defaults. Partner-facing objects use a mix of Apex-managed sharing (`PartnerShareService`/`PartnerShareDomain`) and application-level scoping (record queries filtered by the calling partner's own account) rather than assuming a particular OWD.

## CRUD/FLS

Externally-reachable Apex boundaries (`@AuraEnabled`, the few `@RestResource`/`InvocableMethod` entry points) route business-record access through the application-service layer described above; internal system-context services (`AccessLevel.SYSTEM_MODE`) are narrow and used deliberately for operational writes (audit logs, dead-letter queue, notification delivery) where CRUD enforcement would otherwise silently drop failure evidence — never for exposing business data to a less-privileged caller.

## Guest access

The public partner-registration surface (Experience Cloud, unauthenticated) is a narrowly scoped API (`PartnerAccountRelationshipService`/onboarding registration controllers), not direct object CRUD. Guest users cannot query arbitrary application records.

## External integrations and credentials

Every outbound integration (AI providers, DocuSign e-signature, outbound webhooks) uses Salesforce Named Credentials — no `Password__c`/`API_Key__c`/`Secret__c`-style fields exist anywhere in this package's custom metadata or object schema. Raw HTTP callouts are confined to exactly four adapter classes (`OpenAIProvider`, `AzureOpenAIProvider`, `DocuSignSignatureProvider`, `WebhookDispatchQueueable`) — confirmed by `scripts/ci/architecture_lint.py` (Sprint 45), re-runnable on every future change.

## AI data flows

Every AI interaction is governed: `IntelligenceContextService.buildContext()` builds a CMDT-allowlisted context (never a raw `SELECT *`), `AIInteractionService.execute()` is the single entry point that checks tenant/use-case quotas and permissions before calling a provider, and every interaction (success, block, or failure) is persisted to `AI_Interaction__c` for audit. AI never mutates an authoritative business record directly — proposed actions go through `AgentActionGatewayService`, which re-checks authority at execute time and dispatches to the same command services a human user would use.

## Data retention

Operational/audit records (`Audit_Log__c`, `AI_Interaction__c`, `Event_DLQ__c`) are package-owned data; no automatic purge job exists yet (a genuine gap for a future phase, not built speculatively here — see `docs/sprint45-release-baseline-review.md`).

## Logging

`AuditService.log()`/`LoggingService` never throw back to the calling business transaction. `Correlation_Id__c` (on `PartnerSync_Event__e`, `Event_Publication__c`, `Deal_Event__c`) threads a business operation across its event trail for traceability.

## Webhook security

`Webhook_Endpoint__mdt` stores configuration only, never secrets — delivery uses Named Credentials. Failed deliveries land in the same `Event_DLQ__c` dead-letter mechanism as internal event-consumer failures (Sprint 45), retryable/acknowledgeable from the new Operations Console.

## File security

Uploaded onboarding/evidence files go through standard Salesforce `ContentDocumentLink` association with business-relationship checks before access is granted to a partner.
