# Deal Protection Lifecycle — Sprint 37 Phase 1

## 1. Discovery: most of Sprint 37 already existed, under different names

Before writing any code, the codebase was checked for existing protection-lifecycle infrastructure. It turned out to be substantial and already matched most of Sprint 37's core architecture, just under different object/field names than the doc's literal spec:

| Sprint 37 concept                              | What already existed                                                                                                                                                                                        |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Deal_Protection__c` (authoritative aggregate) | `Deal_Protection_Grant__c` — same role: `Current__c`/`Current_Grant_Key__c` uniqueness, `Version_Number__c` optimistic concurrency, `FOR UPDATE` locking                                                    |
| Activate/Extend/Release/Expire commands        | `DealProtectionCommandService` — already idempotent via a `Deal_Protection_Action__c` command-key ledger, a more sophisticated pattern than the version-check-only approach used elsewhere in this codebase |
| Blocking approval conditions (§37.18)          | `Approval_Condition__c.Condition_Type__c = 'Protection Blocking'` — already checked by `activate()`                                                                                                         |
| Expiry processing via commands (§37.31)        | `DealExpiryBatch` — already queries `Deal_Protection_Grant__c` and issues `Expire Protection` commands, not direct DML                                                                                      |
| Migration of existing dates (§37.44)           | `DealProtectionMigrationBatch` already exists (code-complete; whether it has been run against the org is outside what source control can confirm)                                                           |

Given this, Phase 1's job was not to build a new engine from scratch, but to **verify the existing engine against Sprint 37's Definition of Done and close the real gaps found**.

## 2. Gaps found and fixed (2026-09-25)

**Nothing ever created a `Deal_Protection_Grant__c`.** `DealProtectionCommandService`'s `'Activate Protection'` action had zero production callers — confirmed by grep and by a pre-existing, currently-passing test (`RegistrationLifecycleCommandHandlerTest`) that explicitly asserted `Protection_Start_Date__c`/`Protection_End_Date__c` stayed `null` after final approval. Deals could be fully approved and no commercial protection entitlement was ever created. Fixed: `DealCommandService.execute()` now calls `DealProtectionCommandService` with `'Activate Protection'` immediately after a `FINALISE_APPROVAL` command's deal-status update commits (needed so the protection service's own fresh `FOR UPDATE` re-query sees the just-approved status). A blocking condition or missing policy is caught and logged rather than failing the whole approval — matching Sprint 37's "Pending Conditions" as a legitimate outcome, not an error.

**A second, competing path directly mutated the legacy projection fields.** `DealReviewService`'s `'Protection Extended'` decision wrote `Deal_Registration__c.Protection_End_Date__c` directly, bypassing `Deal_Protection_Grant__c` entirely — a real violation of Sprint 37's "legacy fields are projections only" rule (§37.2), and a data-integrity risk: `DealExpiryBatch` only ever reads the grant's `End_Date__c`, so an extension applied through this path would never be reflected there, and the batch would still expire on the original (un-extended) date. Currently dormant only because **zero LWC ever calls this decision** (confirmed via grep) — an "engine built, no caller" case, but one whose engine was actively wrong rather than just unreachable. Fixed: `extendProtection()` now resolves the deal's current grant and routes through `DealProtectionCommandService`'s `'Extend Protection'` command instead.

**Dead code cleanup.** `DealReviewService.expireProtection()` was called by nothing except its own test — superseded by `DealExpiryBatch` + `DealProtectionCommandService` — removed, along with its now-unreachable `'DealExpired'` platform event (confirmed nothing subscribes to that event type). `DealExpiryBatch`'s class doc comment was also stale, claiming it called `DealReviewService.expireProtection` when its actual body already called `DealProtectionCommandService` — corrected.

## 3. What Phase 1 does NOT cover (deferred, per the "trimmed Phase 1" scope agreed before starting)

Sprint 37's full spec is far larger than what's addressed here. Explicitly deferred:

- `Deal_Protection_Scope__c` and multi-dimension scope (customer/product/territory) — today, scope is implicitly "the whole customer," matching what already existed.
- `Protection_Scope_Hash__c` fingerprinting and protection-vs-protection overlap detection wired into the Sprint 35 conflict engine (§37.13-37.15).
- Suspension, transfer, and the full extension-request workflow (policy validation, review/approval routing) — extension today is a direct command call, not a governed request lifecycle.
- Grace-period policy (`Grace_Conflict_Behaviour__c`) and inactivity monitoring (§37.30, §37.33).
- Co-sell/shared protection hooks (§37.29) — left for Sprint 38.
- The partner-facing `partnerDealProtectionCard` and internal `dealProtectionWorkbench` LWCs (§37.41-37.42) — no UI exists for any of this yet, including the newly-wired activation; it currently only surfaces through the existing `Protection_Start_Date__c`/`Protection_End_Date__c` projection fields wherever those are already displayed.
- The full event catalog (§37.38) — no new platform events were added.
- Bulk/concurrency stress testing at the 200-record scale (§37.46-37.47) — the underlying `FOR UPDATE`/version-check pattern is unchanged and already relied on elsewhere, but no new dedicated bulk test was written for this pass.
- Confirming `DealProtectionMigrationBatch` has actually been run in the org — that's an operational step, not something visible from source control.

## 4. Verification

Apex brace/paren balance and `prettier --check` clean on all touched files; full jest suite (54/54 suites, 182/182 tests) and eslint clean as a regression check (no LWC touched this pass). No `sf deploy`/`sf validate` run — user pushes to the org manually.

## 5. References

- `architecture-design-and-enhancement.md`, Sprint 37 — Protection Lifecycle Engine (the canonical spec this phase partially implements).
- [[project_2gp_package_release_state]] — schema changes here were code-only (no new objects/fields), so this note doesn't apply to this phase.
