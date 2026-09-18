# License and Tier Implementation Plan

**Status: design/planning only — not scheduled.** Per owner decision (2026-07-31, reaffirmed 2026-09-09), tier/license enforcement is intentionally deferred until core PRM functionality has been validated end-to-end as a product, so monetization isn't hardened around a shape that might still change. This document exists so that decision can be revisited quickly and implemented consistently later — it does not authorize starting the work now.

## 1. Purpose

Capture, in one place, what tier/license scaffolding already exists in the schema, what's actually live, and what a consistent implementation would look like — so that whoever picks this up later (possibly a future session with no memory of these conversations) isn't rediscovering the same inventory from scratch or inventing a second, parallel mechanism.

## 2. Two separate "tier" concepts — do not conflate them

The schema currently has two unrelated axes both called "tier." Any implementation must keep them separate.

| Axis             | What it means                                                                                                                                                   | Values                                                                                       | Where it lives                                                                                                                     |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **License tier** | What the _subscriber org_ pays PartnerSync for — a SaaS plan that caps usage and unlocks features                                                               | Trial / Starter / Professional / Enterprise                                                  | `PartnerSync_License_Tier__mdt` (schema only, unwired)                                                                             |
| **Partner tier** | Where an individual _partner account_ sits in the subscriber's own channel program — a business concept the subscriber manages, not something PartnerSync sells | Bronze / Silver / Gold / Platinum / Elite / Strategic (Registered used in one config object) | `Account.Partner_Tier__c` (live picklist, actively read) + `Partner_Tier_Config__mdt` / `Partner_Tier__mdt` (schema only, unwired) |

Partner tier already works today for its actual purpose (dashboard, content visibility, analytics, lead scoring all read `Account.Partner_Tier__c` directly). It is out of scope for this plan — this plan is about **license tier only**.

## 3. Current state inventory

Verified by reading the code directly (2026-09-09), not by assumption:

| Component                                            | Status               | Notes                                                                                                                                                                                                                                                                                                                          |
| ---------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `TenantConfigService` + `Tenant_Config__mdt.Default` | **Live**             | Boolean feature toggles (`Enable_Deals__c`, `Enable_MDF__c`, `Enable_AI__c`, etc.) and numeric caps (`Deal_Expiry_Days__c`, `Max_Open_Deals_Per_Partner__c`, `Lead_SLA_Hours__c`) — called from `DealRegistrationService`, `MDFService`, `PartnerContentService`, `AnalyticsService`, `AIInsightGeneratorService`, and others. |
| `TenantConfigService.getEdition()`                   | **Dead**             | Reads `Tenant_Config__mdt.Edition__c` (Bronze/Silver/Gold/Enterprise). Only caller is a coverage test, not production logic.                                                                                                                                                                                                   |
| `AIUsageService` + `AI_Usage_Day__c`                 | **Live**             | Row-locked (`FOR UPDATE`) daily reservation counter, one flat org-wide cap read from `Tenant_Config__mdt.AI_Daily_Request_Limit`. Not tier-aware — it's a single global number regardless of plan. See [ai-request-quota.md](ai-request-quota.md).                                                                             |
| `PartnerSync_License_Tier__mdt`                      | **Dead**             | 4 records (Trial/Starter/Professional/Enterprise), zero Apex/LWC references. Every `Enable_*` flag is `false` and every `Max_*` cap is `null` on every record — the seed data itself was never finished. No field anywhere points from a tenant to one of these records.                                                       |
| `PartnerSync_Config__mdt`                            | **Dead + duplicate** | Near field-for-field duplicate of `Tenant_Config__mdt`. Looks like `Tenant_Config__mdt` superseded it and it was never deleted.                                                                                                                                                                                                |
| `Feature_Flag__mdt`                                  | **Dead**             | 7 seeded records (AI, Agentforce, Analytics, Content*Hub, Leaderboards, MDF, Notifications, Webhooks) with `Enabled__c` + `License_Tier__c`. Zero Apex/JS references — functionally a second, unwired copy of what `Tenant_Config__mdt`'s `Enable*\*` fields already do live.                                                  |
| `AI_Usage_Limit__mdt`                                | **Dead**             | Per-tier `Daily_Request_Limit__c`/`Monthly_Request_Limit__c` records (Starter/Professional/Enterprise). Zero references — `AIUsageService` reads `Tenant_Config__mdt` instead, entirely bypassing this object.                                                                                                                 |
| `Usage_Metric__c.License_Tier__c`                    | **Dead**             | Field exists with FLS grants in two permission sets, but zero Apex/LWC reads `Usage_Metric__c` at all.                                                                                                                                                                                                                         |
| `AIProviderRouter`                                   | **Not tier-aware**   | Routes purely by feature name → provider config (`AI_Feature_Config__mdt` → `AI_Provider_Config__mdt`). No plan/tier branching.                                                                                                                                                                                                |
| `AIInsightGovernanceService`                         | **Not tier-aware**   | Enforces reviewer _permission_, not caps or tier.                                                                                                                                                                                                                                                                              |

**Bottom line:** every piece of tier-specific schema in the app is unwired. The only real enforcement today is flat, org-wide, and tier-blind.

## 4. Reusable patterns already proven in this codebase

Two patterns already work in production and should be extended rather than replaced:

1. **Named-record + cached static getter** (`TenantConfigService` reading `Tenant_Config__mdt.Default`) — good for simple booleans and single numeric caps.
2. **Row-locked reservation ledger** (`AIUsageService` + `AI_Usage_Day__c`, `FOR UPDATE`, unique day key, seed-from-history on first use) — good for anything metered per period (daily/monthly request counts).

A license-tier implementation should reuse both rather than introducing a third mechanism.

## 5. Proposed model: resolve tier into flat values, don't branch on tier at runtime

Two designs are possible:

- **(A) Live tier lookup:** Apex reads the org's current tier, looks up `PartnerSync_License_Tier__mdt` by that tier name, and branches on the result at call time.
- **(B) Resolved-value:** provisioning (install/upgrade time, not request time) writes the _resolved_ caps directly into `Tenant_Config__mdt` fields, the same way `AI_Daily_Request_Limit` already works today. Runtime Apex never needs to know what tier produced the number.

**Recommendation: (B).** It's already the live pattern (`AI_Daily_Request_Limit` is exactly this — a flat value someone set for this org, not a live join against a shared catalog), it fits this app's actual deployment shape (one subscriber org per install, no true multi-tenancy inside a single org, so there's no "current tenant" to resolve at request time beyond "this org"), and it trivially supports per-customer overrides/negotiated deals without special-casing. `PartnerSync_License_Tier__mdt` becomes a **reference catalog for the provisioning process** (what Starter/Professional/Enterprise are supposed to set), not something Apex queries live.

### Consolidation this implies

- Retire `PartnerSync_Config__mdt` (pure duplicate of `Tenant_Config__mdt`) — independent of tier work, per [[feedback_unused_fields]].
- Retire `Feature_Flag__mdt` — its `Enable_*` role is already covered by `Tenant_Config__mdt`, and its `License_Tier__c` dimension is superseded by design (B): tier maps to whether a `Tenant_Config__mdt.Enable_*` flag was set true at provisioning, not to a separate flag catalog.
- Retire `AI_Usage_Limit__mdt` — same reasoning; `AI_Daily_Request_Limit` already is the resolved value. If a _monthly_ cap is added later, add `Tenant_Config__mdt.AI_Monthly_Request_Limit` following the same pattern rather than reviving this object.
- Finish `PartnerSync_License_Tier__mdt` as documentation/reference data only (fix the null/false seed data so it's accurate as a catalog), or move its content into this doc / a provisioning runbook and delete the object entirely if nothing needs it to exist as queryable metadata.

## 6. Enforcement surface area

What would actually need a cap, and what hook it would use under design (B):

| Capability                                 | Hook                                                                                            | Gap today                                                                                                                                                                                                                             |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AI requests/day                            | `AIUsageService` (exists)                                                                       | Already tier-independent-but-working; just needs the _value_ set per plan at provisioning.                                                                                                                                            |
| Partners per org (`Max_Partners__c`)       | None                                                                                            | Needs a count-and-check at partner-account creation (e.g. `PartnerApplicationService` or wherever an Account gets provisioned as a partner). No reservation ledger needed — a `COUNT()` query against Account is cheap at this scale. |
| Deals per month (`Max_Deals_Per_Month__c`) | None                                                                                            | Would need an `AIUsageService`-style monthly reservation ledger, or a simpler month-bucketed `COUNT()` against `Deal_Registration__c.CreatedDate`, in `DealRegistrationService`.                                                      |
| MDF requests (`Max_MDF_Requests__c`)       | None                                                                                            | Same shape as deals, in `MDFService`.                                                                                                                                                                                                 |
| Webhooks enabled/disabled                  | `Tenant_Config__mdt.Enable_Webhooks__c`-style flag (doesn't exist yet, `Enable_*` pattern does) | Straightforward: add the field, follow the existing `TenantConfigService` pattern.                                                                                                                                                    |
| Portal / Experience Cloud access           | N/A — decoupled by design                                                                       | Per the packaging discussion (2026-09-09), the portal is a separate Lightning Bolt Solution / AppExchange SKU, gated by purchase, not by in-app tier logic. Keep it that way — don't fold it into `Tenant_Config__mdt`.               |

## 7. Phased rollout plan (for whenever this is picked back up)

**Phase 0 — readiness gate.** Do not start until the owner explicitly decides core product validation is sufficient. This phase has no engineering content; it's a go/no-go checkpoint.

**Phase 1 — schema consolidation.** Retire the dead/duplicate objects listed in §5, fix or delete `PartnerSync_License_Tier__mdt` seed data, add any new `Tenant_Config__mdt` fields needed for caps that don't have one yet (`Max_Partners__c`, `Max_Deals_Per_Month__c`, `Max_MDF_Requests__c`, `Enable_Webhooks__c`).

**Phase 2 — provisioning wiring.** Define how a subscriber's purchased plan turns into `Tenant_Config__mdt` field values at install/upgrade time (manual admin-set values initially is fine — this doesn't require automation on day one).

**Phase 3 — new caps enforcement.** Implement the partner-count, deals/month, and MDF-request checks per §6, following the existing `AIUsageService` reservation-ledger pattern for anything period-based.

**Phase 4 — portal SKU.** Convert `org-config`'s Experience Cloud assets into a Lightning Bolt Solution, listed/sold separately (see the packaging discussion referenced above). Independent of Phases 1-3; can happen in parallel or not at all without blocking license-tier work.

**Phase 5 — lifecycle policy.** Decide and implement overage and downgrade behavior (§8) once the caps from Phase 3 exist.

## 8. Open decisions (need product/business input, not just engineering)

- **Overage behavior:** hard block vs. soft warning vs. metered overage billing, per capability. These can differ (e.g. AI requests already hard-block; deals/month might warn instead).
- **Downgrade handling:** what happens to data that's already over a new, lower cap (e.g. an org with 50 partner accounts downgrades to a 25-partner plan) — freeze new creation only, or something more aggressive? Recommend freeze-only (never delete/deactivate customer data as a side effect of a plan change).
- **Trial expiry:** does a Trial tier expire automatically, and what happens to the org's data and access when it does?
- **Portal SKU pricing:** whether the Lightning Bolt Solution is bundled into Professional/Enterprise or sold as a standalone add-on to any tier — a listing/pricing decision, not blocked on anything in this doc.

## 9. Non-goals for this phase

- No live tier-lookup branching in Apex (see §5 — resolved-value design is preferred).
- No changes to `Account.Partner_Tier__c` or the channel-tier objects (§2) — different concept, not in scope.
- No automated billing/metering integration — caps are enforced in-app; charging for overage (if that's ever the policy) is a separate, later integration.

## 10. References

- [[project_license_tier_dead_config]] — origin of this inventory, and the reasoning for deferring this work.
- [ai-request-quota.md](ai-request-quota.md) — the one real, working metering example this plan builds on.
- [appexchange-and-experience-cloud-installation.md](appexchange-and-experience-cloud-installation.md) — portal packaging/SKU context (§6, §7 Phase 4).
