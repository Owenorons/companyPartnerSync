# Deal Process Enhancement v2

**PartnerSync Partner Deal Lifecycle Management (PDLM)**  
**Architecture and delivery specification — Sprints 34–36**  
**Version:** 2.0  
**Date:** 5 August 2026

## Document purpose

This document replaces the earlier deal-process enhancement specification. It retains the enterprise product direction while correcting the command model, transaction boundaries, conflict-analysis security, event-delivery semantics, concurrency controls, and multi-step approval behaviour.

PartnerSync will treat a deal as a living commercial aggregate from draft registration through validation, conflict management, internal review, approval, protection, co-sell, implementation, revenue, renewal, and completion. The platform must remain configurable for smaller organisations, but its control plane must be safe for enterprise partner ecosystems.

## 1. Executive decision

PartnerSync should evolve from a linear deal-registration module into a configurable Partner Deal Lifecycle Management capability.

The target process is:

1. A partner prepares and validates a registration.
2. The platform establishes customer identity and detects commercial overlap.
3. Internal teams resolve conflicts without exposing competing-partner information.
4. Metadata creates the required review and approval work.
5. Authorised users complete review and approval work items.
6. A separate finalisation command records the registration decision.
7. Protection activates only when approval is final and no blocking condition remains.
8. The deal continues through sales execution, implementation, revenue, and renewal.

The following governance rules are non-negotiable:

- Conflict-free submission does not grant approval or protection.
- Submission with a blocking conflict becomes an internal-review case.
- Validation failure is a correct business outcome, not a system failure.
- Work-item completion is distinct from aggregate approval.
- Internal matching may run with privileged record access, but partners receive only sanitised results.
- Every successful business mutation produces one durable event.
- Idempotency and optimistic concurrency are enforced at the command boundary.
- Event publication uses an outbox-style delivery model with callbacks, retries, and subscriber deduplication.
- Exactly one current review plan, approval plan, and conflict-analysis run may exist for a deal.

## 2. Enterprise lifecycle model

The root deal record exposes a concise lifecycle summary. Detailed progress belongs in child aggregates rather than an ever-growing status picklist.

### 2.1 Lifecycle phases

- Discovery
- Registration
- Review
- Protection
- Sales Execution
- Implementation
- Customer Success
- Renewal
- Completed
- Archived

### 2.2 Registration states

- Draft
- Submitted
- Pending Analysis
- Under Review
- Needs Information
- Approved
- Approved with Conditions
- Rejected
- Cancelled
- Expired

### 2.3 Separate lifecycle dimensions

Conflict, review, approval, protection, sales, implementation, revenue, and renewal each maintain their own states. They update the root lifecycle summary only through an explicit coordinator command.

This prevents one overloaded `Status__c` field from representing validation, review work, approval decisions, and commercial outcomes simultaneously.

## 3. Architecture principles

### 3.1 Aggregate boundaries

| Aggregate         | Owns                                      | Does not own                         |
| ----------------- | ----------------------------------------- | ------------------------------------ |
| Deal Registration | submission and registration outcome       | individual reviews or approval steps |
| Conflict Analysis | findings, evidence, resolution, waiver    | final deal approval                  |
| Review Plan       | review requirements and review work items | approval authority                   |
| Approval Plan     | approval steps, decisions, conditions     | conflict investigation               |
| Protection        | protection grants, extensions, expiry     | registration submission              |
| Sales Execution   | stage, probability, opportunity sync      | approval governance                  |

Commands must identify both the aggregate and lifecycle dimension they target. A review command cannot pretend to be a registration transition.

### 3.2 Field ownership

| Field                      | Owning capability      |
| -------------------------- | ---------------------- |
| `Status__c`                | Registration engine    |
| `Conflict_Status__c`       | Conflict engine        |
| `Protection_Status__c`     | Protection engine      |
| `Lifecycle_Phase__c`       | Lifecycle coordinator  |
| `Sales_Stage__c`           | Sales execution engine |
| `Implementation_Status__c` | Implementation engine  |
| `Revenue_Status__c`        | Revenue engine         |
| `Renewal_Status__c`        | Renewal engine         |
| `Version_Number__c`        | Command service        |
| `Last_Lifecycle_Event__c`  | Event service          |

Temporary compatibility writes must be documented, feature-flagged, and removed when the owning capability is delivered.

### 3.3 Security boundary

User-facing services run with sharing and enforce CRUD, field access, record access, custom permissions, and partner ownership.

Cross-partner matching runs inside a narrowly scoped privileged service because a partner must not need access to a competitor's deal for duplicate detection to work. That service:

- accepts only a validated internal context;
- queries only the fields required for matching;
- performs no partner-facing serialisation;
- returns opaque match identifiers and sanitised classifications;
- records internal evidence in private conflict records;
- never exposes competitor name, amount, contact, products, owner, or opportunity details without a separate sensitive-data permission.

`with sharing` alone is not sufficient for cross-partner detection, and system context alone is not sufficient for authorisation. Both concerns must be designed explicitly.

## 4. Canonical command model

### 4.1 Command envelope

```apex
public class DealCommand {
  public String aggregateType;
  public Id aggregateId;
  public Id dealId;
  public String lifecycleDimension;
  public String commandType;
  public String commandKey;
  public String correlationId;
  public String causationId;
  public String source;
  public Integer expectedVersion;
  public String reason;
  public Map<String, Object> parameters;
}
```

Required invariants:

- `dealId`, `aggregateType`, `aggregateId`, `lifecycleDimension`, `commandType`, and `commandKey` are mandatory.
- `commandKey` is globally unique within a tenant. If a future global ledger spans tenants, uniqueness becomes `Tenant Key + Command Key`.
- The same logical retry must reuse the same command key.
- A different business intent must use a new command key.
- Work-item commands use the work item's version, while deal-finalisation commands use the deal version.

Supported aggregate types initially:

- Deal Registration
- Deal Conflict
- Deal Review
- Deal Approval
- Deal Information Request
- Deal Review Plan
- Deal Approval Plan

### 4.2 Command outcome

Not every unsuccessful request is an exception. The result distinguishes business outcomes from technical failures.

```apex
public class DealCommandResult {
  public Boolean accepted;
  public Boolean completed;
  public Boolean duplicateCommand;
  public Boolean retryable;
  public String outcome;
  public Id dealId;
  public Id aggregateId;
  public Id eventId;
  public String commandKey;
  public String previousState;
  public String newState;
  public Integer resultingVersion;
  public String message;
  public List<DealCommandMessage> messages;
}
```

Example outcomes:

- Completed
- Validation Failed
- Needs Information
- Command In Progress
- Version Conflict
- Not Authorised
- Invalid Transition
- Locked
- Routing Failed
- Technical Failure

Validation failure normally completes the command with `outcome = Validation Failed`. This allows findings and a durable event to commit while the UI still presents a corrective result.

### 4.3 Transition definition

`Deal_State_Transition__mdt` must include:

- aggregate type;
- lifecycle dimension;
- from state;
- action;
- to state;
- required custom permission;
- validation handler;
- command handler;
- event type;
- partner visibility;
- reason and expected-version requirements;
- allowed actor classes;
- sort order and description.

Uniqueness is enforced for active definitions by a deterministic key:

`Aggregate Type | Dimension | From State | Action`

### 4.4 State engine

The state engine resolves state for the target aggregate. It does not assume every command belongs to the registration dimension.

```apex
DealCommandContext evaluate(
    SObject aggregate,
    DealCommand command
)
```

The engine validates structure, reason, version, lock, permission, actor class, and configured handler. It performs no DML and no callouts.

## 5. Transaction and idempotency design

### 5.1 Execution sequence

1. Validate the envelope.
2. Attempt to reserve the unique command key.
3. If the key exists, return the stored result or `Command In Progress`.
4. Lock the target aggregate.
5. Recheck expected version.
6. Resolve the transition once.
7. Validate and execute the handler.
8. Persist aggregate changes and domain records.
9. Insert exactly one durable business event.
10. Insert or update the event-outbox record.
11. Complete the command ledger with the serialised result.
12. Commit.

### 5.2 Concurrent retries

The unique ledger key is the concurrency arbiter. A check-then-insert sequence alone is insufficient.

If reservation raises a duplicate-key result, the service re-queries the ledger:

- Completed: return the original stored result with `duplicateCommand = true`.
- Processing: return `Command In Progress`, including a retry-after hint.
- Failed Retryable: allow a controlled retry policy.
- Rejected: return the stored deterministic business outcome.

Two commands using the same expected version but different keys lock the aggregate. Only the first valid mutation succeeds; the second returns `Version Conflict` or `Invalid Transition` after lock acquisition.

### 5.3 Failure semantics

Business failures that must be audited are persisted as outcomes and do not throw after DML. Examples include validation failure, routing failure, and an information request.

Technical failures roll back the domain transaction. A separate failure-observation mechanism may record them using a transaction finalizer or immediate-publish operational event. The business ledger must never imply that a rolled-back mutation completed.

## 6. Durable events and reliable publication

### 6.1 Durable event

`Deal_Event__c` remains the immutable business timeline. It records aggregate type and ID in addition to deal ID, event type, version, dimension, old and new states, action, actor, source, command key, correlation and causation IDs, occurrence time, summary, sanitised payload, and partner visibility.

Events are append-only. Corrections use compensating events rather than edits.

### 6.2 Event outbox

Create `Deal_Event_Outbox__c` or equivalent fields on the durable event:

- Event
- Publication UUID
- Status: Pending, Queued, Published, Failed, Dead Letter
- Attempt Count
- Next Attempt On
- Last Attempt On
- Published On
- Last Error
- Payload Hash

The primary transaction inserts a pending outbox item. A post-commit publisher sends platform events in batches.

An enqueue result is not treated as confirmed publication. A platform-event publish callback marks the record Published or Failed. Retry processing uses exponential backoff and a configured maximum attempt count.

Subscribers deduplicate by durable event ID or publication UUID. Subscriber failure never rolls back the original deal command.

### 6.3 Payload disclosure

Internal and partner payloads are constructed by separate serializers. Setting `Partner_Visible__c = true` does not automatically make the internal payload safe.

Partner payloads may contain:

- the partner's own deal number;
- public lifecycle state;
- corrective requirements;
- approved partner message;
- relevant due date.

They must not contain competing partner, internal opportunity, privileged pricing, internal notes, or confidential evidence.

## 7. Direct mutation guard

Controlled lifecycle fields are blocked in a before-update domain check unless a command-scoped mutation context is active.

The mutation context:

- is internal to the lifecycle package;
- uses a depth counter rather than a Boolean;
- is opened immediately before controlled DML;
- is closed in `finally`;
- has a distinct migration context requiring `PartnerSync_Override_Lifecycle`;
- is treated as an integrity mechanism, not an authorisation boundary.

Custom permissions remain the authorisation mechanism. Profiles and role names must not be hard-coded.

## 8. Sprint 34A — Control plane foundation

### 8.1 Scope

Sprint 34A delivers:

- canonical multi-aggregate command envelope;
- command result and message contracts;
- command ledger and reservation semantics;
- metadata transition selector and state engine;
- namespace-aware permission and type resolution;
- durable event and outbox;
- direct mutation guard;
- version and lock fields;
- bulk execution architecture;
- migration utilities.

It does not implement conflict rules, review plans, approval matrices, or protection policy.

### 8.2 Core objects

`Deal_Command_Execution__c`:

- Tenant Key
- Command Key, unique external ID
- Aggregate Type and Aggregate ID
- Deal
- Command Type
- Status
- Requested, started, and completed timestamps
- Expected and resulting versions
- Result Event
- Request and result payloads
- Error category and sanitised error message
- Retryable and retry count

`Deal_Event__c` and `Deal_Event_Outbox__c` use the model defined in section 6.

### 8.3 Deal fields

- `Lifecycle_Phase__c`
- `Current_Action_Required__c`
- `Current_Action_Owner__c`
- `Next_Action_Due__c`
- `Lifecycle_Health__c`
- `Last_Lifecycle_Change__c`
- `Last_Lifecycle_Event__c`
- `Version_Number__c`
- `Lifecycle_Locked__c`
- `Lifecycle_Lock_Reason__c`

`Last_Command_Key__c` may remain as a diagnostic summary but is not the source of idempotency truth.

### 8.4 Bulk design

`executeBulk` must reserve command keys in bulk, query ledgers once, lock aggregates in deterministic ID order, load metadata once, group by handler, perform set-based selector work, insert records in collections, publish outbox batches, and return record-level results.

It must not loop over the single-record API.

### 8.5 Definition of done

- Active transitions are unique and aggregate-aware.
- Concurrent retries return deterministic results.
- Invalid state and version branches are tested.
- Every committed mutation has exactly one durable event.
- Event publication status is callback-driven and retryable.
- Direct uncontrolled mutations are blocked.
- Bulk execution stays within limits for 200 commands.
- Existing records can be mapped without changing organisation-wide defaults.

## 9. Sprint 34B — Registration commands and compatibility

### 9.1 Registration commands

- Submit Deal
- Request Information
- Resubmit Deal
- Reject Registration
- Cancel Registration
- Finalise Deal Approval

`Approve` is not used for intermediate approval work. Intermediate work uses `Complete Approval Step` against `Deal_Approval__c`.

### 9.2 Submission result

At the end of submission:

- blocking validation findings: Draft or Needs Information;
- no blocking conflict: Submitted;
- blocking conflict: Under Review;
- asynchronous analysis: Submitted plus Pending Analysis.

None of these outcomes activates protection.

### 9.3 Compatibility facades

Existing public service methods remain thin facades. They build commands, preserve idempotency keys across retries, call the command service, and map results into legacy DTOs. They must not perform direct lifecycle DML.

### 9.4 Definition of done

- No-conflict submission remains Submitted without protection.
- Conflict submission becomes Under Review.
- Correctable validation failures persist findings.
- Existing UI and Flow entry points use the facade.
- Partner users cannot approve or reject registrations.
- Internal decisions remain permission-controlled.

## 10. Sprint 35A — Validation and customer identity

### 10.1 Validation engine

Validation rules are metadata-driven and return findings without DML. Categories include completeness, customer identity, account eligibility, opportunity linkage, territory, product, commercial data, partner eligibility, compliance, and data quality.

Findings have severity, blocking status, internal message, partner message, field references, rule key and version, and remediation guidance.

The command handler persists findings and returns a business outcome. It does not save findings and then throw an exception.

### 10.2 Identity normalisation

The normalisation service derives:

- normalised legal and trading names;
- domain and website identity;
- phone and address identity;
- registration and tax identifiers;
- country and ultimate parent;
- a versioned identity fingerprint.

Legal-suffix handling is country-aware. Sensitive identifiers are encrypted or masked and never included in partner-visible output.

### 10.3 In-memory consistency

Normalised identity is created once and passed through a `DealConflictContext`. The conflict engine must not re-query stale fields after the handler modifies only the in-memory deal.

The supported patterns are:

1. construct and pass the full context into analysis; or
2. persist identity first and reload it before analysis.

The preferred synchronous pattern is the first option because it avoids unnecessary intermediate DML.

### 10.4 Fingerprint rules

Fingerprints are deterministic SHA-256 values with an explicit schema version. Missing components are represented explicitly so partial fingerprints cannot collide silently with complete fingerprints. A fingerprint accelerates exact matching but is never the only candidate-selection method.

## 11. Sprint 35B — Conflict engine v2

### 11.1 Conflict findings

`Deal_Conflict__c` records:

- deal and analysis run;
- type, subtype, severity, confidence, match score, and blocking status;
- matched entity references stored privately;
- evidence summary and structured evidence;
- assignment, status, SLA, resolution, waiver, and audit information;
- partner-visible classification and approved partner message.

Conflict types include potential duplicate, existing opportunity, active protection, existing registration, same parent or global account, territory conflict, named or strategic account, same contact only, internal opportunity, competitor-protected scope, and renewal ownership.

### 11.2 Candidate selection

Candidate discovery is staged and set-based:

1. exact identifiers;
2. structured relationships;
3. normalised identity;
4. optional external matching.

The privileged selector may search across partner boundaries. It returns a restricted candidate projection and never returns competitor records to partner-facing code.

### 11.3 Scoring and blocking

Weights and thresholds are metadata-driven and versioned. Fuzzy-name similarity alone cannot confirm a conflict. Confirmed or blocking outcomes require structured evidence such as the same customer account, registration number, opportunity, or active protection scope.

### 11.4 Analysis runs and uniqueness

Every analysis has a run ID, rule-set version, input hash, start and completion time, current flag, and status.

An `Active_Run_Key__c` unique field contains the deal ID while the run is current. Superseding a run clears the old key before the new run receives it. Duplicate input hashes are debounced.

Findings are never deleted during reanalysis. They become superseded, preserving resolutions and waiver history.

### 11.5 Resolution and waiver

Commands target `Deal_Conflict__c`:

- Assign Conflict
- Start Investigation
- Request Evidence
- Submit Evidence
- Confirm Conflict
- Resolve Conflict
- Waive Conflict
- Mark False Positive
- Escalate Conflict
- Reanalyse Deal

Waivers record authority, approver, time, reason, expiry, conditions, and reviewed evidence. Critical waivers require a distinct permission.

### 11.6 Approval guard

Final approval queries current persisted conflict records. Root summary fields are insufficient. Approval is blocked while any current blocking finding remains outside an allowed terminal state.

### 11.7 Synchronous and asynchronous analysis

- Synchronous: exact deterministic matching with small candidate sets.
- Asynchronous: expensive, external, or high-volume matching.
- Hybrid: critical exact rules synchronously, broader analysis asynchronously.

Hybrid is the enterprise default. While broad analysis is pending, the deal cannot receive final protection unless policy explicitly permits it.

### 11.8 Definition of done

- Cross-partner conflicts are detectable without revealing competitors.
- Validation and conflict findings persist consistently.
- Identity fields used by analysis are current.
- Only one current run exists per deal.
- Reanalysis preserves history and is debounced.
- Approval uses persisted blocking conflicts.
- Candidate queries and rule evaluation are bulk-safe.

## 12. Sprint 36A — Routing and review framework

### 12.1 Review plans

`Deal_Review_Plan__c` is the versioned governance plan. `Deal_Review__c` represents each work item.

Review types include channel, sales, commercial, technical, finance, legal, security, compliance, public sector, partner eligibility, strategic account, executive, conflict resolution, implementation readiness, and renewal ownership.

Plans support sequential steps, parallel groups, explicit dependencies, conditional follow-on reviews, blocking and advisory reviews, reassignment, recusal, and waiver.

### 12.2 Current-plan uniqueness

`Current_Plan_Key__c` is unique. It contains the deal ID only for the current plan. Plan creation locks the deal or a dedicated planning mutex, supersedes the current plan, clears its key, and inserts the next version.

This database constraint prevents two concurrent transactions from creating two current plans.

### 12.3 Routing

Routing rules evaluate deal value, currency, country, territory, industry, product, partner tier, strategic status, named account, conflict severity, risk, implementation need, and required skill.

Each required review resolves to:

- a user;
- a queue;
- an explicit fallback operations queue; or
- a controlled routing failure.

Routing failure blocks lifecycle health and creates an event. It never silently leaves a required review unassigned.

### 12.4 Review commands

Commands target the review work item and its version:

- Start Review
- Complete Review
- Request Information
- Resume Review
- Reassign Review
- Recuse Reviewer
- Waive Review
- Escalate Review
- Cancel Review

Completing a review changes `Deal_Review__c`, not the registration state. The review-plan coordinator derives plan progress and may issue the next plan-level command.

### 12.5 Information requests

`Deal_Information_Request__c` stores question, audience, due date, evidence requirement, response, acceptance, SLA, and status.

Opening a partner request may coordinate the root deal to Needs Information. Responding closes or resumes the relevant review and coordinates the deal back to Under Review. Partner messages are sanitized separately from internal notes.

### 12.6 Plan regeneration

Material deal changes create a new plan version. Completed work is preserved and reused only when metadata says the review remains valid for the changed fields, rule version, and age.

### 12.7 Definition of done

- Exactly one current review plan exists per deal.
- Work-item completion never produces a false Approved registration event.
- Required work is always assigned, failed explicitly, or routed to fallback.
- Dependencies and parallel groups behave deterministically.
- Information requests preserve review context and partner confidentiality.
- Plan generation supports 200 deals without per-record metadata or routing queries.

## 13. Sprint 36B — Approval framework

### 13.1 Approval plans and steps

`Deal_Approval_Plan__c` contains the versioned approval process. `Deal_Approval__c` represents one approval work item. `Deal_Approval_Condition__c` records enforceable conditions.

Supported initial models:

- sequential;
- parallel, all required;
- any one authorised approver;
- unanimous.

Quorum may be added when a confirmed customer requirement exists.

### 13.2 Approval authority

Authority is checked at decision time, not merely assignment time. It includes identity, role key, amount, currency, discount, margin, territory, country, product, risk, waiver authority, delegation validity, and effective dates.

An assigned user who has lost authority cannot approve. The step is escalated or regenerated.

### 13.3 Approval-step command

`Complete Approval Step` targets `Deal_Approval__c`.

The result event is, for example:

`Approval Pending → Approval Step Completed`

It is not:

`Submitted → Approved`

After each step, the approval-plan coordinator determines whether the plan is still pending, rejected, returned, approved with conditions, or finally approved.

### 13.4 Finalisation command

Only a completed approval plan can issue `Finalise Deal Approval` against `Deal_Registration__c`.

That command validates:

- no unresolved blocking conflicts;
- all blocking reviews completed successfully;
- no open blocking information requests;
- approval plan is current and final;
- decision snapshots are present;
- authority was valid for each required decision;
- conditions have been classified correctly;
- expected deal version still matches.

It then changes the registration to Approved or Approved with Conditions.

### 13.5 Conditions and protection

- Non-blocking condition: approval final; protection may activate.
- Protection-blocking condition: approval final with conditions; protection remains Pending Conditions.
- Opportunity-blocking condition: protection may activate, but opportunity creation waits.

Protection activation is invoked through a protection command or facade, not performed as an incidental side effect of an intermediate approval step.

### 13.6 Delegation, recusal, and separation of duties

Delegation is time-bound, scoped, auditable, and revalidates the delegate's authority. Users cannot approve their own submitted deal where separation-of-duties policy applies. Recused users cannot be automatically reassigned to the same work item.

### 13.7 Current-plan uniqueness

Approval plans use the same unique current-key pattern as review plans. Generation obtains a deterministic lock and enforces a maximum number of steps.

### 13.8 Definition of done

- Intermediate approvals update only approval work items.
- Command results and events represent the state actually committed.
- Final deal approval is a separate, version-checked command.
- Authority is revalidated at decision time.
- Conditions explicitly control protection and opportunity behaviour.
- Missing approvers never cause automatic approval.
- Exactly one current approval plan exists per deal.

## 14. Permission model

Create or retain permissions for:

- create and submit deal;
- review deal;
- approve or reject registration;
- view, investigate, resolve, reassign, escalate, and waive conflicts;
- view sensitive conflict data;
- complete, reassign, waive, and administer reviews;
- complete, delegate, escalate, and administer approvals;
- activate protection;
- override lifecycle for controlled migration;
- view internal events and replay failed publications;
- administer PDLM metadata.

Dynamic custom-permission resolution must support managed-package namespaces. Permissions are assigned through permission sets and groups, not profile-name checks.

## 15. SLA and escalation

SLA metadata may vary by work type, severity, partner tier, geography, strategic status, and business hours.

Every active work item stores due time, SLA status, escalation level, pause reason, pause time, and accumulated paused duration. Pauses are allowed only for configured reasons and are fully audited.

Dashboards expose due today, at risk, overdue, blocked, unassigned, and escalation workload.

## 16. UI and integration contracts

### 16.1 LWC

The UI calls one command endpoint. It disables duplicate actions, preserves the command key during retry, displays business outcomes separately from technical errors, refreshes the aggregate after completion, and handles version conflicts.

It does not use `updateRecord` for controlled lifecycle fields.

### 16.2 Flow

The invocable action accepts aggregate type and ID, deal ID, dimension, command type, command key, expected version, reason, source, correlation ID, and parameters.

Flows may orchestrate commands but cannot directly assign controlled lifecycle fields.

### 16.3 APIs and integrations

External integrations provide stable idempotency keys. Responses distinguish completed, duplicate, in-progress, rejected business outcome, version conflict, and retryable technical failure.

## 17. Migration

### 17.1 Root mapping

| Existing status | Phase        | Protection summary  | Current action        |
| --------------- | ------------ | ------------------- | --------------------- |
| Draft           | Registration | Not Requested       | Complete Draft        |
| Submitted       | Review       | Not Requested       | Internal Review       |
| Under Review    | Review       | Not Requested       | Resolve Conflict      |
| Approved        | Protection   | Active              | Update Sales Progress |
| Rejected        | Completed    | Not Requested       | No Action             |
| Expired         | Completed    | Expired             | No Action             |
| Closed Won      | Completed    | Active or Expired   | No Action             |
| Closed Lost     | Completed    | Released or Expired | No Action             |

Commercial Closed Won and Closed Lost values remain initially for integration compatibility, while `Sales_Stage__c` is backfilled.

### 17.2 Migration controls

- Run in batches with a dedicated permission and mutation context.
- Initialise versions deterministically.
- Detect ambiguous legacy protection before setting Active.
- Create migration events only when audit requirements justify the volume.
- Reconcile current-plan keys before enabling uniqueness.
- Produce pre- and post-migration counts and exception reports.

## 18. Testing strategy

### 18.1 Command and concurrency

- same key returns one mutation and one event;
- concurrent duplicate key returns completed or in-progress result;
- two keys with one expected version allow only one valid mutation;
- commands target the configured aggregate and dimension;
- namespace-aware permissions and handler resolution work.

### 18.2 Transaction outcomes

- validation findings persist with Validation Failed outcome;
- technical failure rolls back domain data and completion event;
- routing failure commits a blocked business outcome where configured;
- stale in-memory identity is never used;
- outbox state changes only through enqueue and callback rules.

### 18.3 Security

- partner submission detects a protected competitor deal;
- partner cannot query the competitor record or sensitive finding;
- partner-visible payload contains no internal evidence;
- internal sensitive fields require explicit permission;
- record access and custom permission are both enforced.

### 18.4 Plans and approvals

- concurrent generation cannot create two current plans;
- an intermediate approval produces an approval-step event only;
- finalisation fails if the plan, review, conflict, authority, or deal version is invalid;
- delegation and recusal rules are enforced;
- protection-blocking conditions prevent activation.

### 18.5 Bulk and limits

- 200 submissions, analyses, plan generations, and commands are exercised;
- metadata loads once per transaction;
- selectors are set-based;
- platform events publish in lists;
- configured step caps prevent runaway plan generation.

Coverage percentage is not the acceptance standard. Every valid path, invalid transition, security boundary, concurrency branch, and rollback path must be asserted explicitly.

## 19. Delivery plan

| Release        | Outcome                                                                           |
| -------------- | --------------------------------------------------------------------------------- |
| Sprint 34A     | Safe command, ledger, event, outbox, guard, and migration foundation              |
| Sprint 34B     | Registration commands and backward-compatible entry points                        |
| Sprint 35A     | Validation and consistent customer identity                                       |
| Sprint 35B     | Privileged, auditable conflict analysis and resolution                            |
| Sprint 36A     | Metadata-driven routing and review work                                           |
| Sprint 36B     | Multi-step approvals, authority, conditions, and finalisation                     |
| Sprint 37      | Temporal protection grants, extensions, release, and expiry                       |
| Later releases | Sales execution, co-sell, implementation, revenue, renewal, AI copilot, analytics |

Each release is independently deployable, feature-flagged, migration-aware, and backward-compatible at its public service boundary.

## 20. Overall acceptance criteria

Deal Process Enhancement v2 is accepted when:

- the root lifecycle is concise and child aggregates retain operational detail;
- commands identify their target aggregate and dimension;
- validation outcomes persist without transaction rollback;
- conflict analysis sees current normalized identity;
- competing deals are detectable without competitor disclosure;
- idempotency behaves deterministically during concurrent retries;
- event publication is outbox-driven and callback-confirmed;
- subscribers deduplicate events;
- only one current analysis, review plan, and approval plan exists per deal;
- review and approval work-item commands do not falsely transition the deal;
- final approval is separate, version-checked, authority-checked, and conflict-checked;
- protection activates only after final approval and satisfaction of blocking conditions;
- bulk operations meet Salesforce governor constraints;
- migration preserves legacy integrations and produces reconciliation evidence;
- permissions, sharing, sanitisation, and separation of duties pass security tests.

## 21. Final architecture

```text
Partner / Internal UI / Flow / API
                 |
                 v
       Aggregate-aware Command API
                 |
       Command Key Reservation + Lock
                 |
       Metadata State and Policy Engine
                 |
     +-----------+------------+
     |           |            |
Registration  Conflict     Work Items
 Aggregate    Aggregate   Review / Approval
     |           |            |
     +-----------+------------+
                 |
        Lifecycle Coordinator
                 |
     Durable Event + Event Outbox
                 |
          After-commit Publisher
                 |
   Notifications / Analytics / Integrations
```

This architecture preserves PartnerSync's original governance direction while making it safe for real enterprise operations. It prevents false approvals, lost validation evidence, stale conflict analysis, cross-partner visibility failures, duplicate current plans, ambiguous event delivery, and inconsistent multi-step approval results.
