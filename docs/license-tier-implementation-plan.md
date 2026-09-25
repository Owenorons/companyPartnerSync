# License and Tier Implementation Plan

**Status: Phase 1 executed (2026-09-25).** Per owner decision (2026-07-31, reaffirmed 2026-09-09), tier/license enforcement was deferred until core PRM functionality was validated end-to-end. The owner explicitly authorized starting this work on 2026-09-25, satisfying this document's own Phase 0 readiness gate. This revision also corrects the plan against `architecture-design-and-enhancement.md`'s licensing ADR (ADR-043-LIC-001, added to that document after this plan's original 2026-09-09 draft), which uses a different commercial model and metadata-retirement list than this plan originally assumed.

## 1. Purpose

Capture, in one place, what tier/license scaffolding exists in the schema, what's actually live, and what a consistent implementation looks like — so whoever picks this up next isn't rediscovering the inventory from scratch or inventing a second, parallel mechanism.

## 2. Two separate "tier" concepts — do not conflate them

| Axis             | What it means                                                                                                                                                   | Values                                                                                       | Where it lives                                                                                                                     |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **License tier** | What the _subscriber org_ pays PartnerSync for — a SaaS plan that caps usage and unlocks features                                                               | Core / Growth / Enterprise (+ Add-ons)                                                       | `PartnerSync_License_Tier__mdt` (now live, see §3)                                                                                 |
| **Partner tier** | Where an individual _partner account_ sits in the subscriber's own channel program — a business concept the subscriber manages, not something PartnerSync sells | Bronze / Silver / Gold / Platinum / Elite / Strategic (Registered used in one config object) | `Account.Partner_Tier__c` (live picklist, actively read) + `Partner_Tier_Config__mdt` / `Partner_Tier__mdt` (schema only, unwired) |

Partner tier already works today for its actual purpose (dashboard, content visibility, analytics, lead scoring all read `Account.Partner_Tier__c` directly). It is out of scope for this plan — this plan is about **license tier only**.

## 3. Corrected commercial model (per ADR-043-LIC-001)

The master architecture doc's earlier draft used "Trial / Starter / Professional / Enterprise" — the same naming this plan originally used. Its own later self-correction explicitly supersedes that:

> "Retain Core, Growth, Enterprise and Add-ons as the only PartnerSync commercial licensing model. The following historical labels are superseded and must not be used as parallel commercial editions: Trial / Starter / Professional / Enterprise; Essentials / Professional / Enterprise; AI Core / Intelligence / Advanced Intelligence. Trial remains a subscription status, not an edition."

Canonical edition matrix (from the doc):

| Capability                       | Core     | Growth   | Enterprise | Optional add-on    |
| -------------------------------- | -------- | -------- | ---------- | ------------------ |
| Partner onboarding and workspace | Included | Included | Included   | —                  |
| Deal registration and protection | Included | Included | Included   | —                  |
| Basic Content Hub                | Included | Included | Included   | —                  |
| Notifications                    | Included | Included | Included   | —                  |
| Lead distribution                | —        | Included | Included   | —                  |
| MDF management                   | —        | Included | Included   | —                  |
| Performance analytics            | —        | Included | Included   | Enhanced Analytics |
| Advanced workflow automation     | —        | Included | Included   | —                  |
| AI summaries and recommendations | —        | Optional | Included   | AI                 |
| Advanced integrations / webhooks | —        | Optional | Included   | Integration Pack   |

This plan seeds that matrix as-is; exact numeric caps (`Max_Partners__c`, `Max_Deals_Per_Month__c`, etc.) remain a pricing/business decision, not an engineering one — see §8.

## 4. Corrected metadata ownership (per ADR-043-LIC-001)

The 2026-09-09 draft of this plan recommended retiring `PartnerSync_Config__mdt`, `Feature_Flag__mdt`, and `AI_Usage_Limit__mdt` outright. The doc's correction retains the first two for reasons distinct from this app's original duplication problem, and merges (not just deletes) the third:

| Component                       | 2026-09-09 plan said                                       | Doc's correction says                                                                                                                        | What this revision does                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PartnerSync_License_Tier__mdt` | Fix seed data, keep as catalog                             | Central source of truth for Core/Growth/Enterprise                                                                                           | **Done.** Seed data rewritten from 4 unfinished Trial/Starter/Professional/Enterprise records to 3 accurate Core/Growth/Enterprise records; added missing `Enable_Leads__c` field. See §5.                                                                                                                                                                                                                                                                      |
| `PartnerSync_Config__mdt`       | Retire (dead + duplicate of `Tenant_Config__mdt`)          | Retain, "global defaults and kill switches"                                                                                                  | **Not touched — flagged as an open decision, not silently overridden.** Verified again this pass: still a zero-reference, field-for-field duplicate of `Tenant_Config__mdt`, which already fulfills that exact role live. The doc's author most likely reused a plausible name without knowing this org already has a wired object doing this job. See §8.                                                                                                      |
| `Feature_Flag__mdt`             | Retire (dead, superseded by `Tenant_Config__mdt.Enable_*`) | Retain as an operational rollout/kill-switch layer, distinct from commercial entitlement (`PartnerSync_Feature_Entitlement__mdt`, not built) | **Retained, untouched, no code changes.** The doc's distinction (entitlement = "did they buy it," feature flag = "is it operationally on") is real and not something `Tenant_Config__mdt.Enable_*` covers. Left unwired until an actual operational-rollout need exists — wiring it up with no real caller would repeat the exact "engine built, no consumer" anti-pattern already fixed elsewhere in this codebase this phase.                                 |
| `AI_Usage_Limit__mdt`           | Retire (dead)                                              | Merge into a new `AI_Usage_Policy__mdt`                                                                                                      | **Deleted, not merged.** `AI_Usage_Policy__mdt` does not exist and building it — plus rewiring the live `AIUsageService` from its current flat `Tenant_Config__mdt` key-value record onto a new per-edition policy object — is a real, separate change to a working system. Deferred to Phase 3 (§7) rather than bundled into this pass. The old object had zero references and unfinished (null/false) seed data either way, so deleting it now loses nothing. |

## 5. What Phase 1 shipped (2026-09-25)

- **`Tenant_Config__mdt.Edition__c`** — restricted picklist values corrected from the stale `Bronze/Silver/Gold/Enterprise` set to `Core/Growth/Enterprise`; the `Default` record's value corrected from the leftover junk value `Bronze` to `Core`. This field is not cosmetic: `UsageMetricService.log()` already stamps `Usage_Metric__c.License_Tier__c = TenantConfigService.getEdition()` on every usage metric row today, so the stale value was live, silently-wrong telemetry, not just dead schema.
- **`PartnerSync_License_Tier__mdt`** — added the missing `Enable_Leads__c` field (Growth's defining difference from Core in the matrix wasn't representable before), and replaced the 4 unfinished Trial/Starter/Professional/Enterprise records (every `Enable_*` false, every `Max_*` null) with 3 accurate Core/Growth/Enterprise records matching §3's matrix.
- **New `PartnerSyncEntitlementService`** — resolves the org's edition (delegates to `TenantConfigService.getEdition()`, no duplicate mechanism) and exposes `isFeatureEntitled(String featureApiName)` against the `PartnerSync_License_Tier__mdt` catalog. This is resolution/catalog logic only — **nothing calls it yet**. Wiring it into actual feature gates (e.g., should `TenantConfigService.isMdfEnabled()` also require entitlement, and what happens when an org's own `Enable_MDF__c=true` toggle contradicts its edition's entitlement) is a real design question the doc itself splits into a separate `PartnerSyncFeatureAccessService` layer — deferred to Phase 3, not decided unilaterally here.
- **`AI_Usage_Limit__mdt`** — deleted (object, 3 seed records, its static-resource export dump). Confirmed zero references before deletion.
- Full test coverage for `PartnerSyncEntitlementService` (`PartnerSyncEntitlementServiceTest`): Core doesn't entitle MDF, Growth entitles MDF/Leads but not AI, Enterprise entitles AI, an unconfigured edition fails cleanly with a typed exception.

**Explicitly not done in Phase 1**: no enforcement wiring (nothing calls `PartnerSyncEntitlementService` from a real feature gate yet), no `AI_Usage_Policy__mdt`/`AIUsageService` rewire, no `PartnerSyncFeatureAccessService`/`PartnerSyncUsageService`/`PartnerSyncLicenseSyncService` (the doc's fuller service architecture — `LicenseSyncService` specifically requires a real external vendor subscription/entitlement backend this app doesn't have; building it now would be inventing infrastructure with nothing on the other end), no new caps enforcement (`Max_Partners__c` etc. are seeded but nothing counts against them yet), no `PACKAGE_LICENSE_INACTIVE`-style package/LMA license-status check (the package hasn't even been released/promoted yet — see [[project_2gp_package_release_state]]).

## 6. Reusable patterns already proven in this codebase

Two patterns already work in production and are extended, not replaced:

1. **Named-record + cached static getter** (`TenantConfigService` reading `Tenant_Config__mdt.Default`, now mirrored by `PartnerSyncEntitlementService` reading `PartnerSync_License_Tier__mdt` keyed by edition).
2. **Row-locked reservation ledger** (`AIUsageService` + `AI_Usage_Day__c`, `FOR UPDATE`, unique day key) — the pattern any future per-edition AI/usage cap should reuse rather than inventing a third mechanism.

## 7. Phased rollout plan

**Phase 0 — readiness gate.** ~~Do not start until the owner explicitly decides core product validation is sufficient.~~ **Cleared 2026-09-25.**

**Phase 1 — schema + entitlement resolution.** **Done, see §5.**

**Phase 2 — provisioning wiring.** Define how a subscriber's purchased plan turns into `Tenant_Config__mdt.Edition__c` at install/upgrade time (manual admin-set value initially is fine — no automation required on day one, since `Edition__c` is already a plain admin-editable CMDT field).

**Phase 3 — enforcement wiring.** This now covers what the original Phase 1 and Phase 3 both partially described:

- Decide and implement how `PartnerSyncEntitlementService.isFeatureEntitled()` combines with `TenantConfigService`'s existing `Enable_*` toggles (edition sets the ceiling; the admin toggle can't exceed it) — this is the doc's `PartnerSyncFeatureAccessService` layer.
- Build `AI_Usage_Policy__mdt` and rewire `AIUsageService` off the flat `Tenant_Config__mdt.AI_Daily_Request_Limit` key-value record onto a per-edition policy, per §4.
- Implement the partner-count, deals/month, and MDF-request checks against the now-seeded `Max_Partners__c`/`Max_Deals_Per_Month__c`/`Max_MDF_Requests__c` caps, following the existing `AIUsageService` reservation-ledger pattern for anything period-based.

**Phase 4 — portal SKU.** Convert `org-config`'s Experience Cloud assets into a Lightning Bolt Solution, listed/sold separately. Independent of Phases 1-3; can happen in parallel or not at all without blocking license-tier work.

**Phase 5 — lifecycle policy.** Decide and implement overage/downgrade/trial-expiry behavior (§8) once Phase 3's caps exist.

## 8. Open decisions (need product/business input, not just engineering)

- **`PartnerSync_Config__mdt`'s fate** — carried forward from §4: still a verified zero-reference duplicate of the live `Tenant_Config__mdt`, despite the doc listing it as retained metadata. Recommend retiring it in a future pass once confirmed with the owner, rather than acting on it unilaterally here (this plan was itself just corrected once this session for moving on a stale reading of the doc — treating this specific item conservatively).
- **Overage behavior**: hard block vs. soft warning vs. metered overage billing, per capability. These can differ (e.g. AI requests already hard-block; deals/month might warn instead).
- **Downgrade handling**: what happens to data already over a new, lower cap. Recommend freeze-only (never delete/deactivate customer data as a side effect of a plan change).
- **Trial expiry**: does a Trial status expire automatically, and what happens to the org's data/access when it does? (Trial is a subscription status per the doc's correction, not an edition — `Edition__c` alone can't represent it; a separate status field would be needed if this is pursued.)
- **Portal SKU pricing**: bundled into Growth/Enterprise or sold as a standalone add-on to any tier.
- **Exact numeric caps** (`Max_Partners__c` = 25/100/unlimited, etc., seeded in §5) — placeholders reflecting the doc's relative ordering, not a priced commercial decision.

## 9. Non-goals for this phase

- No live external subscription/LMA sync (`PartnerSyncLicenseSyncService`) — no vendor-managed entitlement backend exists to sync against yet.
- No changes to `Account.Partner_Tier__c` or the channel-tier objects (§2) — different concept, not in scope.
- No automated billing/metering integration — caps are enforced in-app; charging for overage (if that's ever the policy) is a separate, later integration.
- No `PartnerSync_Feature__mdt`/`PartnerSync_Feature_Entitlement__mdt` build-out — those are Sprint 43 (AI/Agentforce) constructs the doc itself only recommends, not requires, and nothing in this app needs per-feature entitlement granularity finer than the edition checkbox set yet.

## 10. References

- [[project_license_tier_dead_config]] — origin of this inventory.
- [ai-request-quota.md](ai-request-quota.md) — the one real, working metering example the Phase 3 AI usage policy work builds on.
- [appexchange-and-experience-cloud-installation.md](appexchange-and-experience-cloud-installation.md) — portal packaging/SKU context (§7 Phase 4).
- `architecture-design-and-enhancement.md`, ADR-043-LIC-001 (near end of document) — the canonical licensing correction this revision reconciles against.
