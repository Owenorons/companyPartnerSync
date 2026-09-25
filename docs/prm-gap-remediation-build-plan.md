# PRM Gap Remediation Build Plan

## Background

A 2026-09-24 review compared PartnerSync against real-world PRM platform usage
(Salesforce PRM/Partner Cloud, Impartner, Zift, Channeltivity, Mindmatrix,
PartnerStack) and against PartnerSync's own design docs. The review confirmed
PartnerSync's deal registration, MDF, onboarding, and AI-scoring subsystems are
fully built and in some areas (AI-driven deal risk/lead-fit/partner-health
scoring, next-best-action) ahead of typical real-world PRM deployments.

It also surfaced concrete gaps, listed below in build order. Sequencing is by
technical dependency, not by the original priority list order: e-signature is
first because it establishes an external-callout/retry idiom that the webhook
dispatcher and the certification-reminder batch both reuse later.

Three low-priority items (partner locator/directory, broader incentive/rebate/
SPIFF management beyond MDF, co-sell/account-mapping) are deferred and not
covered here.

## Open decisions required before implementation

These are business or architecture calls, not technical ones — flagged so they
don't get guessed at mid-build:

1. **E-signature UI entry point.** No existing screen calls
   `PartnerAgreementService.releaseForSignature` today. Phase 1 needs a home
   for a "Send for Signature" action (likely the risk-approval workspace or a
   new agreement panel).
2. **Webhook outbound networking model.** Salesforce requires an allow-listed
   destination for outbound HTTP: either a Named Credential per configured
   endpoint (consistent with this app's AI-provider convention, but awkward
   for dynamically-added endpoints) or Remote Site Settings per destination
   host (simpler for admin-configurable URLs, less auditable). Phase 5 is
   blocked on this choice.
3. **Deal attribution classification rules.** What actually distinguishes
   "sourced" vs. "influenced" vs. "assisted" in PartnerSync's process. Phase 7
   needs this defined before the `Deal_Attribution_Rule__mdt` rules can be
   written.

## Phase 1 (High) — E-Signature Provider Adapter

**Problem:** `PartnerAgreementService.releaseForSignature` (partner/
`PartnerAgreementService.cls:133-171`) takes caller-supplied `provider`/
`envelopeId` strings and just records them — nothing calls a real e-signature
provider. Inbound webhook status tracking (`processProviderEvent`, same file,
line 193) is fully implemented; only the outbound send is missing.

**Design — mirrors the existing AI provider pattern exactly**
(`AIProviderRouter.providerFor`, `ai/AIProviderRouter.cls`), so adding a second
provider later is a contained, single-file change:

- `PartnerSignatureProvider` (`partner/PartnerSignatureProvider.cls`) already
  exists and is already provider-neutral (`sendEnvelope(agreement,
signatories)`) — no change needed.
- New `Signature_Provider_Config__mdt`, mirroring `AI_Provider_Config__mdt`:
  `DeveloperName`, `Provider_Name__c`, `Provider_Type__c` (`'DocuSign'` now,
  `'AdobeSign'` later), `Active__c`, `Named_Credential__c`.
- New `PartnerSignatureProviderRouter` (`partner/`), mirroring
  `AIProviderRouter`: queries the active `Signature_Provider_Config__mdt` row,
  switches on `Provider_Type__c` to instantiate a concrete provider, falls
  back to `DisabledSignatureProvider` for anything missing/inactive/
  unrecognized.
- New `DocuSignSignatureProvider implements PartnerSignatureProvider` — the
  only concrete provider built in this phase.
- New `DisabledSignatureProvider` — no-op fallback, mirrors
  `DisabledAIProvider`.
- New `PartnerSignatureCalloutMock` — test mock, mirrors `AIHttpCalloutMock`.
- Modify `PartnerAgreementService`: add `sendForSignature(agreementId)` —
  loads the agreement + signatories, resolves the active provider via the
  router, calls `sendEnvelope(...)`, then calls the existing
  `releaseForSignature` internally so current validation/state logic is
  reused, not duplicated.
- Org-config: new `PartnerSync_DocuSign` external/named credential, following
  the same pattern already deployed for `PartnerSync_OpenAI`/
  `PartnerSync_Azure_OpenAI`.

**Future Adobe Sign support:** a single new `AdobeSignSignatureProvider` class
plus one line in the router's switch. No changes to the interface, to
`PartnerAgreementService`, or to any caller — same zero-blast-radius extension
`AzureOpenAIProvider` got added alongside `OpenAIProvider`. Not scaffolded in
this phase — no code to plug in yet.

**Testing:** mocked-callout unit test; provider-selection fallback test
(defaults to `Disabled` when unconfigured); regression test on the existing
inbound HMAC webhook path.

## Phase 2 (High) — `Partner_Consent__c` / `Partner_Exception__c`

**Problem:** `docs/partner-onboarding-enhancement-v2.md:178-197` names these
two objects in the target data model, and the activation gate contract
(same file, lines 206-219) requires "no expired or revoked gate-releasing
exception" — a condition that can't be enforced because the object doesn't
exist. Every other object in that design table was built; these two weren't.

**Design:**

- New `Partner_Consent__c`: `Onboarding__c`, `Consent_Key__c`, `Policy_Key__c`,
  `Policy_Version__c`, `Accepted_On__c`, `Accepted_By__c`, `Status__c`,
  `Revoked_On__c`.
- New `Partner_Exception__c`: `Onboarding__c`, `Exception_Key__c`, `Gate__c`,
  `Reason__c`, `Approved_By__c`, `Status__c`, `Effective_On__c`,
  `Expires_On__c`.
- Modify the onboarding gate evaluator (the service that sets
  `Activation_Gate_Status__c`) to add these as blocking conditions.
- Mirror `Partner360Service.addBlocker`'s existing pattern
  (`dashboard/Partner360Service.cls:133-140`) so open consent/exception items
  surface in the Partner 360 blockers list alongside the four that already do.
- New LWC: a consent-acceptance panel for the partner-facing side, and an
  exception-grant panel on the internal risk-approval workspace.
- Permission sets: FLS grants for `PSG_Partner_User` (consent, read/create
  own) and `PSG_Internal_Administrator` (exceptions).

## Phase 3 (High) — Deal Detail Page

**Problem:** `psDealList` already dispatches an `opendeal` CustomEvent
(`lwc/psDealList/psDealList.js:77`) that nothing listens to — no Deal Detail
screen exists despite deal registration being the deepest subsystem in the
app (`docs/experience-cloud-page-architecture.md:256-257`).

**Design:**

- New LWC `psDealDetail`: registration data, lifecycle phase, conflict
  status, approval/review history, lifecycle event timeline — reuse the
  event-timeline pattern `psPartner360` already renders.
- Wire `psDealList.js`'s `opendeal` event — either navigate to a new
  `Deal_Detail` site page/route, or open it in the existing, currently
  orphaned `psDrawer` component (closes another inventory gap for free).
- Apex: confirm whether a controller already exposes single-deal detail; if
  not, add one following the existing `DealRegistrationController` pattern.

## Phase 4 (High) — Content Hub Upload Flow

**Problem:** `psContentAdmin` only edits existing `Partner_Content__c` rows
today (toggle active, edit metadata) — no way to add a new asset
(`docs/experience-cloud-page-architecture.md:330-336`).

**Design:**

- Modify `psContentAdmin`: add `lightning-file-upload`, wired to create a
  `ContentVersion` and link it to a new/existing `Partner_Content__c` record.
- New field `Partner_Content__c.Content_Document_Id__c` — follow the naming
  precedent set by `Partner_Agreement__c.Certificate_Content_Document_Id__c`.
- Extend `PartnerContentService` with `createFromUpload(...)`.
- Scope note: this page is internal-only, so no guest/partner upload
  permission exposure to design around.

## Phase 5 (Medium) — Outbound Webhook Dispatch

**Decision:** wire `Webhook_Endpoint__mdt` (`Active__c`, `Endpoint_Name__c`,
`Event_Filter__c`, `Retry_Count__c`, `Timeout_Seconds__c`, `URL__c`) to a real
dispatcher — currently unconsumed scaffolding with zero referencing Apex.

**Design — reuses the existing event fan-out exactly:**

- `PartnerSyncEventHandler.process` (`events/PartnerSyncEventHandler.cls:42`)
  already fans each `PartnerSync_Event__e` out to
  `AuditEventConsumerService.logBusinessEvent` and
  `NotificationEventConsumerService.notifyBusinessEvent`, with per-event
  isolation into `EventDLQService.logFailure` on failure. Add
  `WebhookDispatchConsumerService.dispatchBusinessEvent(eventRecord)` as a
  third fan-out call, same isolation.
- Platform-event triggers can't make synchronous callouts, so the consumer
  enqueues `WebhookDispatchQueueable`, which matches active
  `Webhook_Endpoint__mdt` rows against the event's type via `Event_Filter__c`,
  POSTs the payload respecting `Timeout_Seconds__c`, and retries up to
  `Retry_Count__c` with backoff.
- New `Webhook_Delivery_Attempt__c`, mirroring `Partner_Alert_Delivery_Attempt__c`
  (`Endpoint__c`, `Event_Type__c`, `Attempted_On__c`, `Status__c`,
  `Response_Code__c`, `Error_Detail__c`, `Retry_On__c`).
- Networking model: see Open Decisions above.

**Testing:** mocked HTTP callout, event-filter matching, DLQ path.

## Phase 6 (Medium) — AI Insight Generation UI

**Problem:** `AIInsightGenerationQueueable` has no caller — generation is
enqueue-only (`docs/ai-request-quota.md:6-7`).

**Design:**

- Modify `psAiInsightPanel`: add a "Generating…" state using the existing,
  currently-unused `psLoadingState`/`psEmptyState` primitives, polling
  `AIInsightSelector` for the resulting `AI_Insight__c` row until it appears
  or times out.
- Apex: minor addition if needed to correlate a request to its eventual
  insight record — confirm during implementation whether an existing key
  already supports this.

## Phase 7 (Medium) — Partner Revenue Attribution

**Problem:** `Deal_Registration__c` has no field distinguishing sourced vs.
influenced vs. assisted revenue — a 2026 PRM-analytics expectation per the
research review.

**Design:**

- New `Deal_Registration__c.Attribution_Type__c` (picklist), governed by a new
  `Deal_Attribution_Rule__mdt` — consistent with how `Deal_Validation_Rule__mdt`
  and `Deal_Conflict_Scoring_Rule__mdt` already drive deal behavior via config
  rather than hardcoded logic. Blocked on the business-rules decision above.
- Modify `AnalyticsService`/`AnalyticsDomain`/`AnalyticsSelector` to break down
  aggregates by the new field — must reuse the bulk-query bounding pattern
  from `docs/analytics-and-mdf-corrections.md` (2026-09-19), not regress it.
- Extend `psPartnerKpiDashboard`/`psPartnerLeaderboard` using the existing
  `psDashboardMetricCard` child component.

## Phase 8 (Medium) — Deal Approval Engine Completion + Training/Certification Extension

**Phase 8a — Deal Approval Engine Completion (folded in 2026-09-24):**

**Problem:** while scoping vendor-configurable approval steps, found that the
multi-step engine (`Deal_Approval_Step_Rule__mdt` → `Deal_Approval_Plan__c`/
`Deal_Approval__c`) already had the right shape but was unwired —
`DealApprovalPlanService.generate()` had zero production callers, so
`DealApprovalFinalisationGuard.assertReady()` always threw and every real
"Approve" click in `psDealReviewWorkspace` failed. Two dead, unwired CMDT
types (`Approval_Routing_Config__mdt`, `Approval_Rule__mdt`) also existed
with an `Approver_Role__c` concept that pointed at real permission sets.

**What shipped:**

- Role resolution repurposed into `Deal_Approval_Step_Rule__mdt` itself:
  `Assignment_Type__c` (now a picklist: `Permission Set` default, `Current
User`) + new `Approver_Permission_Set__c`. `Deal_Approval__c` snapshots the
  permission set; any internal user holding it can decide the step — no
  single pre-picked assignee. `Approval_Routing_Config__mdt`/
  `Approval_Rule__mdt` deleted (fully redundant once merged in).
- `DealApprovalCommandService.assertAuthority()` checks permission-set
  membership (`PermissionService.hasPermissionSet`, new
  `getPermissionSetNames()` helper) when there's no exact `Assigned_To__c`.
- `RegistrationLifecycleCommandHandler.routeSubmission()` now calls
  `DealApprovalPlanService.generate()` automatically on submit/resubmit —
  the fix for the broken Approve path. Required a version-override overload
  on `generate()` since the deal's own version bump hasn't persisted yet at
  that point in the transaction.
- New workspace for step-deciders who aren't full deal reviewers:
  `DealApprovalController`/`DealApprovalWorkspaceService`/
  `DealApprovalSelector`/`DealApprovalDomain` + DTOs, and LWC
  `psDealApprovalWorkspace`, added alongside `psDealReviewWorkspace` on the
  `Deal_Review` Experience Cloud CMS page.
- Permission sets `PartnerSync_Channel_Manager`/`PartnerSync_Internal_Admin`/
  `PartnerSync_Deal_Reviewer` granted `Deal_Approval__c`/
  `Deal_Approval_Plan__c` access + the new controller.

**Explicitly out of scope:** `Deal_Review__c`/`DealReviewPlanService` (a
separate, equally-unwired review-checklist engine — not blocking today since
zero active review rules means zero blocking reviews); making
`Sequence__c`/`Parallel_Group__c` actually gate step ordering (all steps in
a plan remain independently decidable; the plan completes once all are
`Completed`).

**Phase 8b — Training/Certification Extension:**

**Problem:** `Partner_Training_Assignment__c` already has `Expires_On__c` —
the foundation exists, it's just scoped to onboarding only, and nothing acts
on expiry.

**Design:**

- Loosen `Onboarding__c` to optional and add `Partner_Account__c`, so
  assignments can exist post-onboarding (minimal change vs. a new object).
- New `PartnerCertificationReminderBatch`, mirroring `DealExpiryBatch`/
  `PartnerLifecycleGovernanceBatch`: finds assignments nearing/past
  `Expires_On__c`, flips status, and fires the existing `PartnerSync_Event__e`
  — automatically picked up by notifications and (once Phase 5 lands) the
  webhook dispatcher, no extra wiring needed.
- Badge tie-in: feed a "certifications current" metric into
  `Badge_Rule_Config__mdt`'s existing generic `Metric_Name__c`/`Threshold__c`
  mechanism — reuses `Partner_Badge__c` gamification with no new schema.

## Phase 9a (enterprise-standard follow-up) — Generalize the Approval Engine

**Superseded Phase 8a's object/class names.** Everything Phase 8a shipped
under `Deal_Approval_Plan__c`/`Deal_Approval__c`/`Deal_Approval_Condition__c`/
`Deal_Approval_Step_Rule__mdt` and the `DealApproval*` Apex/LWC family was
renamed and genericized to `Approval_Plan__c`/`Approval__c`/
`Approval_Condition__c`/`Approval_Step_Rule__mdt` and `Approval*`
(`force-app/main/default/classes/approvals/`), so MDF (Phase 9c) and any
future approval-needing object can plug into the same engine instead of
Deal getting a second parallel copy. Deal's own approval behavior is
unchanged end-to-end — this was a pure refactor. Key mechanics: a typed
`Deal__c` lookup became `Object_Name__c` (Text) + `Target_Record_Id__c`
(Text 18); a new `Target_Amount__c`/`Target_Label__c` pair, populated by the
calling object's own command handler at generation time, replaces what used
to be a live relationship join for amount/display purposes. Deal-specific
finalisation preconditions (blocking `Deal_Review__c`/
`Deal_Information_Request__c`) moved out of the shared
`ApprovalFinalisationGuard` into `RegistrationLifecycleCommandHandler`
directly, since they don't apply to other objects.

Pre-existing design docs (`docs/deal-process-enhancement-v2.md`,
`docs/pdlm-permission-reconciliation.md`) still reference the old
`Deal_Approval_*` names in places — left as historical record of the
original design intent, not updated as part of this refactor.

## Phase 9b (enterprise-standard follow-up) — MDF Calculation Engine

CMDT-driven eligible-funding calculation for MDF requests, keyed on a new
`Tenant_Config__mdt.Industry__c` (Metadata Relationship to a new `Industry__mdt`
catalog, so the tenant's industry selection and the calculation rules can't
drift out of sync the way two independent picklists could). New
`MDF_Calculation_Rule__mdt` (`Industry__c`, `Campaign_Type__c`,
`Calculation_Model__c`, `Rate__c`, `Cap__c`, `Minimum_Amount__c`/
`Maximum_Amount__c`) drives `MDFCalculationEngine`, which collapses every
"model" to one formula (`requested × rate, clamped to cap`) rather than three
separate code paths. Writes `MDF_Request__c.Eligible_Amount__c` at submission
(informational only); `MDFApprovalService.approve()` soft-blocks a decision
that exceeds it, reusing the existing `PartnerSync_Approval_Override`
authority rather than a new permission. No active rule matching = no ceiling
= today's behavior, so tenants with nothing configured see no change.

**Flagged then, still true:** this repo's first-ever use of the
`MetadataRelationship` field type, with no prior precedent to verify the XML
shape against — check in Setup on first deploy that `Tenant_Config.Default`'s
`Industry__c` actually resolves to `Industry__mdt.General`.

## Phase 9c (enterprise-standard follow-up) — Wire MDF into the Approval Engine

The payoff of Phase 9a's generalization: MDF requests now get a real
multi-tier pre-approval chain by calling the same engine Deal uses, just with
`Object_Name__c = 'MDF_Request__c'` — no new generic Apex, no new UI (MDF
steps show up in the existing `psApprovalWorkspace` queue alongside Deal
steps). `MDFService.submitRequest()` generates the plan after insert;
`MDFApprovalService.approve()` gates the _final_ decision on the chain being
complete (reject is ungated, same reasoning as Deal). Ships one default rule,
`Approval_Step_Rule.MDF_Reviewer` (routed to `PartnerSync_MDF_Reviewer`, the
same set that already does final approval), so out-of-the-box behavior is
unchanged — one step, same reviewer — while vendors can add tiers via CMDT
alone. MDF has no resubmission cycle or version field, so both `generate()`
and `assertReady()` use a constant `0` rather than building version-tracking
infrastructure with nothing to guard.

**Found and fixed a real pre-existing bug along the way:**
`MDFService.submitRequest()` discarded the return value of
`SecurityUtil.stripForCreate()` (`Security.stripInaccessible()`, which
returns new SObject instances, not the same references) and then used the
original `record.Id`/fields afterward — meaning the `MDFSubmitted` platform
event, the audit log entry, and the internal-reviewer log line had likely
been firing with a null record Id since this code was written. Fixed by
capturing and using the actually-inserted record, matching the safe pattern
`DealRegistrationService.cls` already uses.

## Phase 9d (enterprise-standard follow-up) — Approval Chain Return/Recovery Path

Phase 9c's "no resubmission cycle" note undersold a real defect: once a
mid-chain `Approval__c` step is decided `'Returned'`, the parent
`Approval_Plan__c` sticks in `Returned` status forever — `Approval-
FinalisationGuard.assertReady()` fails permanently, and the record it gates
has no path back to a working state. This isn't MDF-specific; it's a gap in
the shared engine from Phase 9a. Deal only _appears_ unaffected because its
`Needs Information → Resubmit` cycle is driven by unrelated
`DealValidationEngine` findings at submission and just happens to
regenerate the plan as a side effect — a chain-level Return with no
independent validation findings driving that cycle would strand a Deal
exactly the same way.

**Engine fix (generic, benefits both objects):** `ApprovalCommandService
.coordinate()` now publishes a `PartnerSync_Event__e`
(`'ApprovalPlanReturned'`) whenever a plan's decision is `'Returned'`
(`Rejected` stays terminal — a human decision, no recovery path needed).
The engine only publishes; it doesn't know or care what, if anything,
reacts.

**Reaction (MDF only, this phase):** new `ApprovalReturnConsumerService`,
dispatched from `PartnerSyncEventHandler` alongside the other three
consumers. For `Object_Name__c = 'MDF_Request__c'`, it flips the record to
a new `'Needs Information'` status and records the return reason on a new
`MDF_Request__c.Return_Reason__c` field (SYSTEM_MODE, direct update — safe
because `MDFService`/`MDFApprovalService` are flat services with no
permission-gated state machine to route through). New
`MDFService.resubmitRequest()` (+ `MDFController` entry point) lets the
owning partner regenerate the plan and flip back to `Submitted`. The
partner-facing `psMdfList` surfaces the return reason and a "Resubmit"
action when a request needs information.

**Deliberately deferred, not silently dropped:** `Deal_Registration__c` has
the identical latent gap. Fixing it means safely driving
`DealCommandService`'s permission-gated state machine
(`Deal_State_Transition__mdt`, authority checks tied to the _interactively
deciding user_) from an automated event consumer — a materially harder,
separate problem that deserves its own research pass rather than a rushed
bolt-on here. `ApprovalReturnConsumerService` explicitly no-ops for any
object name other than `MDF_Request__c`, with a comment pointing back at
this section.

**Follow-up hardening:** `Approval_Plan__c.Status__c`, `Approval__c.Status__c`,
and `Approval_Condition__c.Status__c` were plain Text fields — every value
written to them (`'Pending'`, `'Approved'`, `'Approved with Conditions'`,
`'Rejected'`, `'Returned'`, `'Superseded'` / `'Completed'`, `'Routing
Failed'` / `'Open'`) came from a fixed, small set in Apex, so the freeform
Text left them one typo away from a value nothing recognized. Converted all
three to non-restricted Picklists (same convention as `MDF_Request__c
.Status__c`/`Deal_Registration__c.Status__c`) — Setup now shows the real
value list, and since Apex treats picklist fields as `String` regardless,
no Apex changed. Safe as a pure schema change since no package version has
ever been released or promoted for this app.

## Deferred (low priority, revisit later)

- Public partner locator/directory (Account already has tier/type/region to
  drive it).
- Broader incentive/rebate/SPIFF management beyond MDF.
- Co-sell/account-mapping (Crossbeam-style) — even market leaders usually
  treat this as a separate bolt-on, not native PRM.
- **`Deal_Registration__c`'s approval-chain Return/Recovery gap** (see Phase
  9d) — a `'Returned'` chain-level decision strands the Deal's approval plan
  with no way back, same root cause MDF had before Phase 9d. Deal isn't
  actively broken today only because its unrelated `Needs Information →
Resubmit` cycle happens to regenerate the plan as a side effect. Needs a
  dedicated pass to safely drive `DealCommandService`'s permission-gated
  state machine from an automated event consumer.
