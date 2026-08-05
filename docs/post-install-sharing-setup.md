# PartnerSync Post-Install: Sharing Set Setup

PartnerSync ships its data model with `Private` (or `Read`-only external, see below)
sharing and enforces partner scoping in Apex. It does **not** ship pre-configured
Sharing Sets, because a Sharing Set must be assigned to a Profile, and PartnerSync
does not create or depend on a specific customer Profile — you're using whichever
Experience Cloud license your org already has (`Partner Community User`,
`Customer Community Plus User`, `External Apps User`, etc.). This is the one
setup step every installing org must complete by hand.

## What to configure

Go to **Setup → Digital Experiences → Sharing Sets**, create one Sharing Set,
assign it to your org's partner-facing Profile(s), and add these access mappings:

| Object                    | Mapping                                         | Access     |
| ------------------------- | ----------------------------------------------- | ---------- |
| `Deal_Registration__c`    | `Partner_Account__c` = `User.Contact.AccountId` | Read/Write |
| `MDF_Request__c`          | `Partner_Account__c` = `User.Contact.AccountId` | Read Only  |
| `Partner_Performance__c`  | `Partner_Account__c` = `User.Contact.AccountId` | Read Only  |
| `Partner_Notification__c` | `Partner_Account__c` = `User.Contact.AccountId` | Read Only  |
| `AI_Insight__c`           | `Partner_Account__c` = `User.Contact.AccountId` | Read Only  |
| `Usage_Metric__c`         | `Partner_Account__c` = `User.Contact.AccountId` | Read Only  |

`Deal_Registration__c` is Read/Write at the Sharing Set level because partners can
submit deals; the actual decision-making transitions (approve/reject/etc.) still go
through `DealReviewService`, which is internal-user-only regardless of record
access. Every other object above should stay Read Only — all writes to them go
through Apex services that enforce their own rules on top of this baseline
visibility.

## What does _not_ need a Sharing Set

- **`Partner_Content__c`** — its `externalSharingModel` is `Read`, so every
  authenticated partner user can already see published content without a Sharing
  Set. Which items they actually see is still governed by
  `PartnerContentDomain.isVisibleToPartner()` (`Visibility__c` +
  `Partner_Tier__c`/`Partner_Type__c` matching) — that's a business rule enforced
  in Apex, not a record-sharing concern, so the record itself is visible while the
  _content_ returned to the UI stays governed by tier/type.
- **Analytics/AI aggregate objects** (`Partner_Performance__c` is the one that
  exists today) — partners reach these exclusively through `AnalyticsService`/
  `AnalyticsController`, which already scope every query to the caller's own
  `Partner_Account__c`. A Sharing Set here is defense in depth, not the only
  thing standing between a partner and someone else's numbers.
- **Anything AI-audit or prompt/log-shaped** — no such object exists in this
  package yet. If one is added later (e.g. a raw AI request/response log), it
  should stay internal-only (no Sharing Set, no partner-facing Apex path).

## Objects referenced in earlier planning that don't exist yet

`Partner_Certification__c`, `MDF_Budget__c`, `Executive_Insight__c`,
`Partner_Performance_Snapshot__c`, and `Content_Analytics_Snapshot__c` appear in
some sharing design notes but haven't been built. There's nothing to configure
for them until they exist — this doc will need a follow-up pass once they do.

## Apex Managed Sharing (exceptions on top of this baseline)

Co-sell access, cross-team escalation, and conflict-review access are handled by
`PartnerShareService` (`Partner_Record_Share__c` + `Partner_Access_Group__c`),
which is independent of Profiles entirely — it shares to Public Groups resolved
per partner account. See `PartnerShareService`, and the `psPartnerShareManager`
LWC (drop it onto the Deal Registration or MDF Request record page) for the
admin-facing grant/revoke UI.

### Schedule the expired-share cleanup batch

`PartnerShareCleanupBatch` revokes any `Partner_Record_Share__c` grant whose
`Expiry_Date__c` has passed — but it implements `Schedulable` and is never
scheduled automatically by deployment. Without this step, expired grants (and
their underlying `Deal_Registration__Share`/`MDF_Request__Share` rows) stay
active indefinitely. This is the second manual post-install step every
installing org must complete, alongside the Sharing Set above.

Run `scripts/apex/schedule-partner-share-cleanup.apex` once per org (VS Code:
right-click the file → "Execute Anonymous Apex", or
`sf apex run --file scripts/apex/schedule-partner-share-cleanup.apex --target-org <alias>`).
It's safe to re-run — it checks for an existing scheduled job with the same
name before scheduling a new one.

### Schedule the deal expiry batch

`DealExpiryBatch` moves any `Approved` `Deal_Registration__c` whose
`Protection_End_Date__c` has passed to `Expired` — same story as the cleanup
batch above: it implements `Schedulable` but is never scheduled automatically
by deployment. Without this step, deals stay `Approved` (and protected)
indefinitely past their protection window. This is a third manual post-install
step every installing org must complete.

Run `scripts/apex/schedule-deal-expiry.apex` once per org the same way as
above. Also safe to re-run.

### Schedule partner provisioning reconciliation

`PartnerProvisioningReconciler` prevents partner applications from remaining
in `Queued` indefinitely when an asynchronous provisioning or terminal-status
job is aborted or never completes. It marks requests older than 24 hours as
`Failed`, allowing an administrator to retry them.

Run `scripts/apex/schedule-partner-provisioning-reconciliation.apex` once per
org. It runs hourly and is safe to execute again because it checks for an
existing scheduled job first.
