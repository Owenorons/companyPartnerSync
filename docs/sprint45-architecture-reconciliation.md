# Sprint 45 Phase 1 — Architecture Reconciliation Audit

`architecture-design-and-enhancement.md` §45.2–§45.11 asks for a "legacy vs. canonical" reconciliation matrix, illustrated with an example table (`Component | Legacy | Canonical | Action`) using class names like `ExpireDealRegistrationsSchedulable` and `LeadDistributionQueueable`. Those class names do not exist in this codebase — the doc's table is a template, not a literal description of this project's history. This document is the **real** audit, run directly against the current source, in place of the doc's illustrative table.

## Method

For each of the doc's four flagged risk areas, every matching call site was grepped and individually read (not just counted) to distinguish a genuine architectural violation from an expected, centralized call.

## 1. Lifecycle-field DML (`Status__c`, `Conflict_Status__c`, `Protection_Status__c`)

**Finding: clean.** `Conflict_Status__c` is written in exactly three production classes:

- `DealRegistrationDomain.cls` (domain layer — sets the initial `'None'` value on creation)
- `RegistrationLifecycleCommandHandler.cls` (command layer — `'Potential Conflict'`/`'None'` transitions)
- `DealReviewService.cls` (the canonical internal review/decision **orchestrator** for approve/reject/resolve-conflict/extend-protection — not a legacy bypass; see its class doc comment)

`DealReviewService.cls` was specifically checked against the doc's §45.3 "legacy `DealReviewService.approveDeal()`" example (direct `deal.Status__c = 'Approved'` + `deal.Protection_Start_Date__c`/`Protection_End_Date__c` DML). No such pattern exists — protection is explicitly routed through `DealProtectionCommandService`, with an in-code comment explaining why (`Deal_Protection_Grant__c` is authoritative as of Sprint 37; `Protection_Start/End_Date__c` on the deal is a system-managed projection only `DealProtectionCommandService.syncSummary()` may write). This is already the canonical shape the doc asks Sprint 45 to migrate _to_ — not a legacy path to replace.

**Action: none.**

## 2. `EventBus.publish` outside the durable-outbox pattern

**Finding: clean.** `EventBus.publish` is called from exactly two classes in the whole codebase: `PlatformEventPublisherService.cls` and `EventPublicationService.cls` — both are the canonical durable-outbox publisher layer. No domain or command class calls `EventBus.publish` directly.

**Action: none.**

## 3. Hard-coded permission-set/custom-permission names in domain logic

**Finding: clean, with one clarification.** A broad search turned up ~10 files with hard-coded `'PartnerSync_...'` string literals. Every one of them passes that literal as an _argument_ to the centralized permission-check API (`PermissionService.hasPermissionSet()`/`hasAnyPermissionSet()`, `PartnerPermissionService.can*()`, or Salesforce's own `FeatureManagement.checkPermission()`) — none of them re-implement permission checking with raw `PermissionSetAssignment`/`Profile` SOQL. The doc's §45.61 concern is about domain logic bypassing the centralized check, not about a literal string being passed into it (which is the expected, only way to call these APIs). This is not an architectural violation.

**Action: none.**

## 4. AI provider calls outside the AI gateway

**Finding: clean.** Raw `new Http()`/`new HttpRequest()` callouts exist in exactly four classes: `ai/OpenAIProvider.cls`, `ai/AzureOpenAIProvider.cls` (the only two AI provider implementations, invoked exclusively through `AIProviderRouter`/`AIInteractionService`), `partner/DocuSignSignatureProvider.cls` (the e-signature integration adapter), and `events/WebhookDispatchQueueable.cls` (the outbound webhook adapter). No domain or command class makes a raw callout.

**Action: none.**

## Conclusion

This codebase's architecture discipline — one canonical write path per aggregate, a single durable event-publish layer, centralized permission checks, and callouts confined to adapter classes — has held consistently across all 44 prior sprints. Sprint 45's reconciliation finds no legacy debt requiring migration, replacement, or a compatibility facade. The doc's own illustrative reconciliation table (§45.2) does not describe this project; this document supersedes it as the actual record.
