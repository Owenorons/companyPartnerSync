# PartnerSync Strict LWR Solution Update

This project implements PartnerSync as an AI-powered Partner Relationship Management product built natively on Salesforce Experience Cloud with a strict LWR runtime.

## Architecture Guardrails

- All external partner pages must be LWR Experience Cloud pages composed from Lightning Web Components.
- Do not introduce Aura components, Visualforce pages, OmniStudio dependencies, global DOM scripting, or unmanaged script injection for partner-facing functionality.
- Partner-sensitive LWC data access must go through Apex facades that enforce feature flags, partner scope, CRUD/FLS, and record-level access checks.
- Feature availability must be controlled by `Tenant_Config__mdt` and permission sets, not client-only conditionals.
- Reusable UI belongs in shared LWCs; workflow logic belongs in module-specific workspace components.

## Partner Isolation Contract

Every partner-visible Apex entry point should follow this order:

1. Check the relevant `TenantConfigService` feature flag.
2. Resolve the current partner account through `PartnerAccessService`.
3. Enforce CRUD/FLS through `SecurityUtil`.
4. Assert record scope through `PartnerRecordAccessService`.
5. Execute service-layer logic.
6. Audit meaningful actions.
7. Return sanitized DTOs only.

Current mandatory access gates:

- `assertPartnerAccessToLead`
- `assertPartnerAccessToDeal`
- `assertPartnerAccessToMdf`
- `assertPartnerAccessToNotification`
- `assertPartnerAccessToContent`
- `assertPartnerAccessToAIInsight`

## AI Recommendation Contract

AI is advisory, not the system of record. Recommendations should be generated from governed Salesforce data and surfaced as explainable cards.

Required controls:

- AI feature flag through `TenantConfigService.isAiEnabled()`.
- Usage metering through `Usage_Metric__c`.
- Prompt and provider policy through protected metadata.
- PII minimization before provider calls.
- Confidence, rationale, and source signal on every recommendation.
- Auditable accept/dismiss/click feedback before recommendations influence automation.

Current UI contract:

- `PartnerAIController.getMyInsights()` returns explainable `AIInsightDTO` records.
- `PartnerAIController.getMyNextBestActions()` returns `NextBestActionDTO` cards.
- `psAiInsightPanel` and `psPartnerNextBestActions` render loading, error, empty, and populated states in LWR.

## Content Enablement Contract

`Partner_Content__c` is the canonical partner-facing wrapper over Salesforce Files.

Rules:

- Do not expose raw `ContentDocumentId` access without server-side visibility validation.
- Content visibility is calculated from active flag, visibility, partner tier, and partner type.
- Downloads must be logged to `Content_Usage_Log__c` and audited.
- Usage events should feed analytics and future content recommendations.

## Packaging Readiness

Before tenant activation, validate:

- Required custom metadata exists.
- Permission sets are assigned.
- Sharing settings and sharing sets are configured.
- LWR pages use only LWC-compatible components.
- CSP Trusted Sites and Named Credentials are configured for AI providers.
- Static resource metadata bootstrap records match source-format object metadata.

## Immediate Backlog

- Add negative Apex tests for `Partner_Content__c` and `AI_Insight__c` cross-partner access.
- Add recommendation feedback fields or a dedicated recommendation feedback object.
- Add tenant readiness validation UI for admins.
- Add AI prompt policy metadata and provider failover settings.
- Add LWR page metadata once the Experience Cloud site is generated.
