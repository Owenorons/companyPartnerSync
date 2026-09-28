# PartnerSync Operations Runbook

A markdown reduction of `architecture-design-and-enhancement.md` §45.52–§45.53/§45.72's "Operations Console"/"support diagnostic package" asks. Written for the internal administrator (Channel Manager/Internal Admin persona) operating a PartnerSync org day to day.

## Where to look

- **`psSetupHealthCheck`** (Experience Cloud page, backed by `PartnerSyncSetupController.getReadiness()`) — one-time and ongoing setup readiness: core metadata, permission groups, onboarding policy, scheduled automation, Experience Cloud, AI configuration, dead-letter backlog, AI usage health, analytics freshness (the last three added in Sprint 45). Run this first when something seems off.
- **`psOperationsConsole`** (new in Sprint 45, linked from `psInternalDashboard`'s "Operations Console" button) — the day-to-day event recovery and AI governance health view.

## Reading the dead-letter queue

Every event a consumer (audit log, notification, webhook dispatch, approval-return, customer-success) fails to process lands in `Event_DLQ__c` instead of being silently lost (`EventDLQService.logFailure()`, existing since before Sprint 45).

Each row has a status:

| Status     | Meaning                                                                                |
| ---------- | -------------------------------------------------------------------------------------- |
| `New`      | Failed once; not yet investigated.                                                     |
| `Retried`  | An admin retried it and reprocessing succeeded — closed.                               |
| `Failed`   | An admin retried it and it failed again — needs investigation, not just another retry. |
| `Resolved` | An admin reviewed it and dismissed it without retrying (e.g. the event is now moot).   |

**Retry** (`psOperationsConsole`'s Retry button → `PartnerSyncOperationsConsoleController.retryDeadLetter()` → `EventDLQService.retry()`) reconstructs the original event from its stored payload and reprocesses it synchronously, outside the trigger's per-batch isolation. Bounded to 5 attempts (`EventDLQService.MAX_RETRY_COUNT`) — past that, the row must be investigated manually (check `Error_Message__c`, check whether the underlying cause — a bad config, a missing permission, a downstream outage — has actually been fixed before retrying again).

**Acknowledge** marks a row `Resolved` without retrying — use this when the event is genuinely moot (e.g. a duplicate, or the record it referred to has since been deleted/superseded), not as a way to make a backlog number look smaller.

**When to escalate rather than retry**: a row stuck at `Failed` after a retry, or a `New` backlog that keeps growing faster than it's worked down, usually means the underlying cause (a misconfigured Named Credential, a missing permission, a downstream outage) hasn't actually been fixed yet — fix that first, then retry.

## Reading AI governance health

The same console surfaces:

- **Failed / Blocked AI interactions** (`AI_Interaction__c.Status__c` = `Failed`/`Blocked-Policy`/`Blocked-Quota`) — a spike usually means a provider credential issue (check `AI_Provider_Config__mdt.Active__c` and the Named Credential) or a quota being hit (check `AIUsageService`'s tenant/use-case limits).
- **Proposed / Failed AI recommendations** (`AI_Recommendation__c.Status__c`) — proposed recommendations awaiting a human decision through `AgentActionGatewayService.executeAction()`; failed ones mean the underlying command service rejected the action at execute time (authority is always re-checked then, even if it was allowed at propose time).

## Analytics freshness

`psSetupHealthCheck`'s "Analytics freshness" check reflects whether `ExecutiveSnapshotBatch` has run in the last day. A `WARNING` here almost always means the batch isn't scheduled, or is scheduled but failing — check scheduled jobs (`configureOperationalAutomation()` on the setup page reschedules the standard PartnerSync jobs) and confirm `PartnerPortfolioSnapshotBatch` (which `ExecutiveSnapshotBatch` depends on) ran first that day.

## What this runbook doesn't cover

Real AppExchange support-tier SLAs, a hosted status page, or automated alerting/paging are not built — see `docs/sprint45-release-baseline-review.md`'s Known Adaptations for what a future phase would need.
