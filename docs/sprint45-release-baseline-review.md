# Migration, Hardening & Release Baseline — Sprint 45

## 1. What shipped (2026-09-28)

All 7 phases of the approved plan (`architecture-design-and-enhancement.md` §45, lines ~23884-26248, "Sprint 45 — Migration, Hardening & AppExchange Release") were built in this pass, scoped to the deterministic hardening/reconciliation substance a pre-first-install package can genuinely act on — real AppExchange submission, penetration testing, and a Setup Wizard against a live subscriber org are out of scope (§3 below), matching this project's consistent treatment of aspirational release-engineering content across every prior sprint.

1. **Architecture reconciliation** — a real, grep-and-read audit of the actual codebase (not the doc's own illustrative "legacy vs. canonical" table, whose example class names — `ExpireDealRegistrationsSchedulable`, `LeadDistributionQueueable` — don't exist here) across the doc's four flagged risk areas: lifecycle-field DML, `EventBus.publish` usage, hard-coded permission-set names, and AI provider calls. All four came back clean — no legacy debt to migrate, replace, or wrap in a compatibility facade. Documented in `docs/sprint45-architecture-reconciliation.md`.
2. **Dead-letter operations** — `EventDLQService.retry()`/`.acknowledge()` (bounded to 5 attempts), a new `PartnerSyncEventHandler.reprocess()` entry point for single-event redrive outside the trigger's per-batch isolation, `PartnerSyncOperationsConsoleController`, and the new internal `psOperationsConsole` LWC (dead-letter queue table with retry/acknowledge actions, plus AI interaction/recommendation health tiles — closing the long-standing `psAiGovernanceConsole` gap by folding AI governance visibility into the same console). Wired into `psInternalDashboard`.
3. **Health check extension** — `PartnerSyncSetupController.getReadiness()` (existing, extended rather than replaced) gained three new checks: dead-letter backlog, AI usage health (failure rate when a provider is active), and analytics snapshot freshness (`Executive_Snapshot__c.Computed_On__c` within the last day).
4. **Negative security / sharing isolation suite** — `PartnerCrossIsolationSecurityTest.cls`: Partner A/B fixtures proving Partner B cannot load Partner A's deal detail, Partner B's own deal/renewal lists never include Partner A's records, and an external partner user is rejected outright from the internal-only revenue-dispute queue. AI context isolation was already covered by Sprint 43's `PortfolioIntelligenceControllerTest` and not duplicated.
5. **Architecture static-check script** — `scripts/ci/architecture_lint.py`, a re-runnable local release-gate scanning for `EventBus.publish` outside the two canonical publisher classes, raw HTTP callouts outside the four established adapter classes, and `Conflict_Status__c`/`Protection_Status__c` writes outside the domain/command layer. Currently clean (0 hard failures, 1 benign review-only finding in the shared test-data factory).
6. **Documentation** — this review doc, `docs/security-overview.md`, and `docs/operations-runbook.md` (markdown reductions of the doc's PDF asks, matching this project's existing `docs/*.md` convention).
7. **Verification** — see §5.

**Verification**: every phase was checked for Apex brace/paren balance and XML well-formedness; `prettier --check`, `eslint`, and a full `sfdx-lwc-jest` run were clean at the end, at **68/68 suites, 251/251 tests** (up from 67/67, 246/246 at the start of this build). No `sf deploy`/`sf validate` — user pushes to the org manually.

## 2. Real gaps found and fixed along the way (not in the original plan)

- **`AI_Recommendation__c.Interaction__c` is a required lookup, but 3 test files across Sprints 43-44 inserted `AI_Recommendation__c` fixtures without populating it** (`PortfolioIntelligenceControllerTest.cls` ×2, `PartnerOperationsCommandCenterControllerTest.cls`, `ExecutiveSnapshotBatchTest.cls`) — these inserts would have failed with `REQUIRED_FIELD_MISSING` the first time they actually ran against a real org. Never caught earlier because Apex tests in this entire multi-sprint session have only ever been syntax/balance-checked locally, never executed against a live Salesforce org (no `sf deploy`/`sf validate`, per the standing instruction — the user runs and pushes manually). Found via a systematic script (checking every required Lookup/Master-Detail field against every `new X__c(...)` construction site in `classes/`), manually verified against false positives (13 of 17 additional raw hits were legitimate `Database.update(..., Id = ...)` partial updates or pure-function unit tests with no `insert` at all), and fixed in all 4 real occurrences plus 2 more in `PartnerReassignmentCommandServiceTest.cls`/`RenewalOpportunityCommandServiceTest.cls` (missing `Partner_Renewal__c.Customer_Success_Engagement__c`, also required).
- **Adding `ExecutiveSnapshotComputed` to `NotificationEventConsumerService`'s maps would have been a real bug** — already caught and avoided during Sprint 44 itself (see that sprint's own review doc), re-confirmed clean during this sprint's reconciliation audit rather than re-introduced.
- **The architecture lint script's first draft flagged `PlatformEventPublisherService.cls` as a violation of its own allowlist** — the file actually lives at `classes/PlatformEventPublisherService.cls` (package root), not `classes/events/`, which the script's initial allowlist assumed by pattern-matching the sibling `EventPublicationService.cls`'s location. Fixed by checking the real path before trusting the pattern.
- **A naive "any `Status__c` write outside the domain layer" heuristic produced ~150 findings, almost all false positives** — `Status__c` is a near-universal field name across dozens of unrelated objects in this schema (AI requests, onboarding, MDF, disputes, etc.), so a bare field-name grep has no way to tell a Deal-lifecycle violation from a completely unrelated object's ordinary field write. Narrowed the script's third check to `Conflict_Status__c`/`Protection_Status__c` only — both distinctive enough to the Deal aggregate to stay a precise, useful signal — rather than shipping a "static check" that would cry wolf on every future run.

## 3. Known Adaptations (deliberate, labeled, not silently dropped)

1. **No actual AppExchange submission, security-review engagement, or penetration test** — external process/vendor engagement, not `force-app` source.
2. **No PDF documentation** — produced as `docs/*.md` instead.
3. **No Setup Wizard UI or environment scan against a real subscriber org** — premature without a live subscriber install (first beta still pending); `psSetupHealthCheck`/`PartnerSyncSetupController` (existing, extended this sprint) is the real equivalent for this project's current stage.
4. **No versioned data-migration framework for prior installs** — no earlier version of this package has ever been installed in a subscriber org.
5. **No capability registry for unintegrated optional Salesforce products** (Agentforce Setup config, CRM Analytics, Data Cloud, Revenue Cloud, CPQ, MuleSoft, Slack) — none are referenced anywhere else in this codebase.
6. **No CI/CD pipeline changes** — this repo has real local static-analysis tooling (`scripts/ci/*.js`, a Code Analyzer baseline) but no hosted pipeline; `scripts/ci/architecture_lint.py` follows that same local, re-runnable convention rather than inventing pipeline config for infrastructure that doesn't exist.
7. **No release-channel/semver tooling or automated Release Manifest generator** — 2GP package versioning is a manual, user-owned step.
8. **No external product telemetry** — no such vendor integration exists or is planned.
9. **No new `PartnerSyncCapabilityService` abstraction layer** — reuses `TenantConfigService`/`PartnerPermissionService`, matching the project's own "no competing config layer on top of `Tenant_Config__mdt`" finding from earlier in this session.

## 4. What a future phase would need to complete

- Real AppExchange Security Review submission and a genuine penetration-test engagement, once the org is ready to commercially release (Adaptation #1).
- A Setup Wizard and environment-scan flow, once a real subscriber-org installation exists to scan (Adaptation #3).
- A versioned migration framework, once a real installed base exists to migrate from (Adaptation #4).
- Automated retention/purge for `Audit_Log__c`/`AI_Interaction__c`/`Event_DLQ__c` — flagged as a real gap in `docs/security-overview.md` but not built speculatively here, since no retention policy has been decided yet.
- The packaging/licensing workstream continuing under its own numbering (`docs/license-tier-implementation-plan.md`), separate from this sprint.

## 5. References

- `architecture-design-and-enhancement.md`, Sprint 45 (§45, lines ~23884-26248) — the canonical spec this build implements, scoped to its deterministic hardening/reconciliation substance.
- `docs/sprint45-architecture-reconciliation.md` — the real audit record this sprint's Phase 1 produced, replacing the doc's own hypothetical illustrative table.
- `docs/security-overview.md`, `docs/operations-runbook.md` — this sprint's markdown reductions of the doc's PDF documentation asks.
- `docs/analytics-executive-operations-command-center-review.md` — the prior sprint's review doc this one follows the same format as, and whose `Executive_Snapshot__c`/`PartnerOperationsCommandCenterController` this sprint's health check and operations console directly build on.
