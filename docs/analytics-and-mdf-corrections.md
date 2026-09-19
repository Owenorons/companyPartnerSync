# Analytics and MDF functional corrections

## KPI definitions

- Accepted leads include distribution statuses `Accepted` and `Converted`.
  Conversion therefore preserves acceptance credit. Acceptance and conversion
  rates retain the same denominator: all leads currently assigned to the partner.
- Open registration pipeline includes `Submitted`, `Needs Information`,
  `Under Review`, and `Approved`. Draft, rejected, cancelled, expired, converted,
  and closed registrations are excluded.
- Win rate is won opportunities divided by closed opportunities (won plus lost).
  Open opportunities and registration counts do not affect its denominator.
  Salesforce's `IsWon` and `IsClosed` flags support subscriber-defined stages.
- Empty denominators produce zero. Null revenue and budget amounts contribute zero.

Partner KPIs, the leaderboard, and account-based health scoring share the same
aggregate inputs and domain calculations. The leaderboard uses one account query
and eight aggregate queries, plus its existing permission checks. Each aggregate
groups only by partner, preserving the existing 1,000-partner leaderboard bound
without multiplying groups by lifecycle status. User-mode queries continue to
enforce record visibility and field permissions. The executive permission set
includes read-only access to the fields these calculations require.

These changes do not introduce reporting periods, leaderboard pagination, or
scheduled snapshots. Synchronous aggregate row limits still apply to very large
activity volumes. The separate customer-revenue report is unchanged.

## MDF approval integrity

Approval and rejection lock the request before validating its current status.
Approval then locks the partner account before checking and incrementing budget
consumption. All decisions use the same request-then-account lock order.
Partner budget reads remain unlocked for cacheable UI queries.

Required decision and consumption fields must be editable; missing access fails
before either write. A savepoint protects the budget and request together, even
when a caller catches a later write exception. The savepoint is released after
success or rollback. Repeated decisions on an already-decided request are rejected.

## Regression coverage

- A leaderboard with 30 populated partners and one empty partner checks bounded
  query usage, isolation between partners, and agreement with health scoring.
- Domain tests cover acceptance after conversion, excluded pipeline statuses,
  won/lost/open opportunity cohorts, custom stage labels, and empty activity.
- MDF tests cover repeat decisions, competing consumption of a shared budget,
  exact-budget approval, over-budget rejection, existing override permissions,
  and rollback when the request write fails after the account update.

True concurrency requires separate Salesforce transactions. In an isolated test
org, approve a request for 6,000 against a 10,000 budget with 2,500 already used,
hold that transaction open briefly, and concurrently approve a second request
for 6,000. The second command must wait and then reject the approval; the final
consumption must be 8,500, with only the first request approved. Repeat with both
commands targeting the same request to verify that a stale decision cannot
consume the budget again.

## Validation on 19 September 2026

- Namespaced scratch org: `psync-functional-fixes-v2`.
- All 31 tests passed across `AnalyticsDomainTest`, `AnalyticsServiceTest`,
  `MDFApprovalServiceTest`, `MDFDomainTest`, `MDFSelectorTest`,
  `ControllerErrorContractTest`, and `CoverageBusinessFlowTest`.
  Successful deployment/test job: `0Af8s00000eRWrCCAW`.
- Separate concurrent requests: one approval succeeded, the other waited and
  failed the budget check. Persisted consumption was 8,500 with one approved
  request and one submitted request.
- Concurrent decisions on the same request: one approval succeeded; the other
  waited and was rejected because the request was already decided. Persisted
  consumption remained 8,500.
- Formatting, project configuration, and whitespace checks passed.

Validation deployed the core source without permission-set groups because the
repository's existing unqualified group membership references failed in the
namespaced scratch-org source deployment. The tested roles were assigned their
permission sets directly. This validates the fixes, not a new 2GP version,
subscriber installation, or upgrade; no package version was published.
