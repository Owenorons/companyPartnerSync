# PartnerSync UI/UAT Testing Sprint

## 1. Objective

Validate PartnerSync `0.1.0.5` (`04tQE00000if8t7YAA`) as a user would experience it in Salesforce Lightning and Experience Cloud. This sprint complements automated Apex and Jest coverage; it focuses on rendered UI, persona permissions, end-to-end workflows, cross-partner isolation, usability, accessibility, and recoverable error handling.

## 2. Entry criteria

- Beta `0.1.0.5` is installed in the UAT org.
- The namespace-safe post-install smoke test passes.
- `./scripts/post-install.sh` has been run with the exact package version ID.
- PartnerSync Operations app pages and record pages are activated.
- An Experience Cloud site is configured and published.
- Sharing Sets and Sharing Rules have been reviewed and activated.
- Named/External Credentials are configured for any AI tests. Secrets are not stored in source control.
- Email deliverability is appropriate for the test environment.
- Browser pop-up blocking does not prevent Salesforce authentication or downloads.

## 3. Test personas

| Persona                    | Suggested access                                            | Purpose                                                  |
| -------------------------- | ----------------------------------------------------------- | -------------------------------------------------------- |
| Internal Administrator     | `PSG_Internal_Administrator`                                | Setup, automation, AI, content, broad operational access |
| Channel Manager            | `PSG_Channel_Manager`                                       | Applications, deals, MDF, dashboards, Partner 360        |
| Onboarding Approver        | Onboarding governance/approval group(s)                     | Approval and risk gates                                  |
| Access Approver            | `PSG_Partner_Onboarding_Access` with approval authority     | Approve requested partner access                         |
| Access Provisioner         | `PSG_Partner_Onboarding_Access` with provisioning authority | Provision approved access                                |
| Operational Manager        | `PSG_Partner_Operational_Monitoring`                        | Operational alerts and lifecycle monitoring              |
| Partner A Administrator    | `PSG_Partner_Administrator`                                 | Partner A administration and partner-facing work         |
| Partner A User             | `PSG_Partner_User`                                          | Normal portal user for Partner A                         |
| Partner B User             | `PSG_Partner_User`                                          | Isolation control user for Partner B                     |
| Unprivileged Internal User | No PartnerSync permission sets                              | Negative authorization testing                           |
| Guest Applicant            | No login                                                    | Public application submission                            |

Use separate named users. Do not reuse the Internal Administrator as a negative-test persona.

## 4. Required test data

- Partner A: active Gold Reseller with two contacts and active portal users.
- Partner B: active Silver Distributor with one active portal user.
- One pending partner application with no matching Account.
- One pending application with a possible Account/Contact match.
- One rejected application.
- Two customer Accounts and at least three Opportunities, including one eligible and one ineligible deal.
- Partner A deals in Draft, Submitted, Approved, Rejected, Conflict, and Expired states where supported.
- Partner B deal for isolation testing.
- Partner A leads in Assigned, Accepted, Rejected, and convertible states.
- Partner A MDF budget plus requests in Draft/Submitted/Approved/Rejected states.
- Active public content, tier-restricted content, type-restricted content, and inactive content.
- Read, unread, high-priority, and dismissed notifications.
- One open operational alert and one resolved alert.
- AI provider configuration for success testing and a deliberately invalid non-production configuration for failure testing.

Use synthetic data only. Prefix records with `UAT-<scenario ID>-` for cleanup and traceability.

## 5. Execution rules

- Run scenarios in the listed order; later streams depend on earlier setup and onboarding outcomes.
- Record browser, device/viewport, user, timestamp, scenario ID, result, screenshot, and created record IDs.
- A scenario passes only when every acceptance criterion passes.
- Log defects with expected versus actual behavior, reproduction steps, persona, URL, record IDs, screenshots, console errors, and severity.
- Do not work around a failed authorization test by granting broader permissions.

## 6. Ordered UI scenarios

### Stream A — Installation and setup health

#### UI-001 — Open PartnerSync Operations

**Persona:** Internal Administrator  
**Steps:** Open App Launcher, select **PartnerSync Operations**, and visit each available navigation item.

**Acceptance criteria:**

- The app opens without a blank page or unhandled error.
- PartnerSync Setup and Partner 360 navigation items are visible where configured.
- Every navigation item opens the intended page and preserves the PartnerSync app context.
- No missing-component error is displayed.

#### UI-002 — Setup health check

**Persona:** Internal Administrator  
**Steps:** Open **PartnerSync Setup**, select **Run checks again**, and inspect every configuration check.

**Acceptance criteria:**

- A loading state appears while checks run and disappears afterward.
- Core and portal readiness summaries agree with the detailed checks.
- Passed checks, warnings, and blockers have distinguishable labels—not color alone.
- Each blocker explains the corrective action without exposing secrets.
- Refreshing does not duplicate setup records or jobs.

#### UI-003 — Configure operational automation

**Persona:** Internal Administrator  
**Steps:** From Setup Health Check, invoke the automation configuration action twice.

**Acceptance criteria:**

- The first action completes with a clear success message.
- The second action is idempotent and does not create duplicate scheduled jobs.
- The UI reports configured state after refresh.
- An unprivileged internal user cannot invoke the action.

### Stream B — Guest application and internal review

#### UI-004 — Submit a valid guest partner application

**Persona:** Guest Applicant  
**Steps:** Open the public application page, populate all required company, location, tier, partner type, contact, and business fields, accept required declarations, and submit.

**Acceptance criteria:**

- Required fields and formats are validated before submission.
- A single application is created with the entered values.
- A confirmation state appears without revealing internal record IDs or review data.
- Refresh/back does not silently create a duplicate application.

#### UI-005 — Validate guest application errors

**Persona:** Guest Applicant  
**Steps:** Submit blank required fields, malformed email/website data, invalid combinations, and an overlong text value.

**Acceptance criteria:**

- Submission is blocked and focus moves to or clearly identifies the first invalid field.
- Field-level messages are specific and understandable.
- Previously valid values remain populated.
- No Apex exception, stack trace, or Salesforce implementation detail appears.

#### UI-006 — Search and claim an application

**Persona:** Channel Manager  
**Steps:** Open Partner Application Review, search for the UAT application, select it, and claim it.

**Acceptance criteria:**

- Search narrows the list without a full-page failure.
- The detail panel matches the selected application.
- Claim identifies the current reviewer and prevents conflicting ownership.
- A second reviewer sees the updated ownership after refresh.

#### UI-007 — Review potential matches

**Persona:** Channel Manager  
**Steps:** Select the application with possible Account/Contact matches and attempt approval before and after acknowledging the matches.

**Acceptance criteria:**

- Potential matches are visible with enough information to make a decision.
- Creation of new records is blocked until the acknowledgement is selected when required.
- Acknowledgement does not automatically approve the application.
- Existing records are not duplicated when the reviewer selects/reuses a valid match.

#### UI-008 — Approve application and request provisioning

**Persona:** Channel Manager, then appropriate onboarding/access personas  
**Steps:** Approve the application, complete required approval/readiness/contracting stages, then request provisioning.

**Acceptance criteria:**

- Approval creates or links the intended Account and Contact exactly once.
- Onboarding status, stage, blockers, tasks, and events are visible and consistent.
- Contract/readiness/access gates cannot be skipped by UI navigation or refresh.
- Provisioning cannot occur before its separate approval and provisioning authorities act.
- Successful provisioning produces an auditable status and does not expose credentials.

#### UI-009 — Reject application

**Persona:** Channel Manager  
**Steps:** Start rejection, cancel once, then reject with a reason.

**Acceptance criteria:**

- Cancel leaves the application unchanged.
- Confirmation requires a meaningful rejection reason.
- Rejection updates status once, records the decision, and removes it from the pending queue.
- The applicant does not gain portal access.

### Stream C — Experience Cloud shell and access

#### UI-010 — Partner login and navigation

**Persona:** Partner A User  
**Steps:** Log in to the published Experience Cloud site and traverse header, top navigation, navigation menu, footer, and browser back/forward actions.

**Acceptance criteria:**

- Login lands on the intended PartnerSync home page.
- Navigation labels and active states are correct and keyboard operable.
- Header/footer branding and links render without broken assets.
- The user never sees internal-only setup, review, or administration pages.
- Session timeout/logout returns to an appropriate public or login page.

#### UI-011 — Responsive and keyboard shell

**Persona:** Partner A User  
**Steps:** Test desktop, tablet, and mobile widths; navigate using keyboard only; open and close drawers/modals with keyboard and backdrop.

**Acceptance criteria:**

- No horizontal clipping prevents primary actions.
- Focus is visible and follows a logical order.
- Escape closes modal/drawer UI and returns focus to the triggering control.
- Dialogs expose an accessible name and trap focus while open.
- Icons and status indicators have meaningful accessible labels.

### Stream D — Partner home and dashboard

#### UI-012 — Partner home dashboard

**Persona:** Partner A User  
**Steps:** Open Home and compare partner status, Open Deals, Assigned Leads, Open MDF, and quick actions with source records.

**Acceptance criteria:**

- Counts include only Partner A records and match the underlying data.
- Empty, loading, and error states are visually distinct.
- Register Deal, View Leads, MDF, and Content quick actions navigate correctly.
- Refreshing the page does not change counts unexpectedly.

#### UI-013 — Internal operations dashboard

**Persona:** Channel Manager and Operational Manager  
**Steps:** Open Internal Dashboard; inspect pending counts, work queues, alerts, filters, and record navigation.

**Acceptance criteria:**

- Counts agree with visible queue records and persona authority.
- Restricted counts are zero/hidden for an unprivileged user.
- Filters update results consistently and can be cleared.
- Selecting a work item opens the correct record or workspace.
- Operational alert history distinguishes open, acknowledged, and resolved states.

### Stream E — Deal registration and review

#### UI-014 — Register a valid deal

**Persona:** Partner A User  
**Steps:** Select an eligible Opportunity, enter estimated revenue, close date, timeline, business problem, solution, and notes, then submit.

**Acceptance criteria:**

- Only eligible Opportunities appear.
- Required fields, positive revenue, and valid dates are enforced.
- One Partner A deal is created and displayed in My Deals.
- Success feedback is clear and repeated clicks do not create duplicates.
- The deal begins in the expected lifecycle state.

#### UI-015 — Deal validation and feature limits

**Persona:** Partner A User  
**Steps:** Attempt submission with missing data, an ineligible Opportunity, past close date, duplicate request, disabled deals, and open-deal cap reached.

**Acceptance criteria:**

- Each invalid action is blocked with a safe, actionable message.
- No partial Deal Registration is left behind.
- Disabled/cap states explain why submission is unavailable.
- Manipulating a URL or browser state cannot submit another partner’s Opportunity.

#### UI-016 — My Deals list and detail navigation

**Persona:** Partner A User  
**Steps:** Open My Deals with several statuses, select each record, and exercise empty state in a user with no deals.

**Acceptance criteria:**

- Only Partner A deals appear.
- Status labels and key values match records.
- Selecting a deal opens the correct detail.
- Empty state offers the intended Register Deal action.

#### UI-017 — Internal deal queue filters

**Persona:** Channel Manager  
**Steps:** Search and filter the Deal Review Workspace by status and conflict; select different deals.

**Acceptance criteria:**

- Search, status, and conflict filters combine correctly.
- Result count and empty state update predictably.
- Detail never remains stale when selection changes.
- Partner, customer, conflict, validation, and lifecycle data match the selected deal.

#### UI-018 — Approve, reject, and conflict-control a deal

**Persona:** Channel Manager/authorized reviewer  
**Steps:** Approve a valid submitted deal; cancel then confirm rejection of another; attempt approval with unresolved conflict or stale version.

**Acceptance criteria:**

- Approval updates lifecycle state once and creates the expected audit/event evidence.
- Rejection requires a reason; cancel makes no change.
- Unresolved conflict and stale-version approvals are blocked safely.
- Buttons disable or show progress during processing to prevent double decisions.
- An unauthorized internal user cannot approve or reject.

### Stream F — Lead distribution and conversion

#### UI-019 — View and accept an assigned lead

**Persona:** Partner A User  
**Steps:** Open Partner Leads, inspect SLA/status information, and accept an assigned lead.

**Acceptance criteria:**

- Only Partner A assignments appear.
- SLA and status labels match source records.
- Acceptance updates the selected lead once and refreshes available actions.
- Partner B cannot see or act on the lead.

#### UI-020 — Reject an assigned lead

**Persona:** Partner A User  
**Steps:** Reject an assigned lead and refresh/reopen the page.

**Acceptance criteria:**

- Status remains rejected after refresh.
- Accept/convert actions are no longer incorrectly offered.
- The decision is auditable and cannot be applied to another partner’s lead.

#### UI-021 — Convert an accepted lead

**Persona:** Authorized internal converter or supported UI persona  
**Steps:** Convert an accepted lead with and without an existing customer match.

**Acceptance criteria:**

- Conversion is unavailable before acceptance or without authority.
- Existing customer matching avoids duplicate Accounts.
- Successful conversion creates/links the expected customer and Opportunity records.
- Repeated conversion is idempotent or safely rejected.

### Stream G — MDF

#### UI-022 — View MDF budget and requests

**Persona:** Partner A User  
**Steps:** Open MDF Workspace and compare annual, used, available values and request list with records.

**Acceptance criteria:**

- Budget arithmetic is correct and formatted consistently.
- Only Partner A requests appear.
- Loading, empty, and disabled-feature states are understandable.

#### UI-023 — Submit an MDF request

**Persona:** Partner A User  
**Steps:** Submit a valid request with campaign, dates, requested amount, and required supporting information.

**Acceptance criteria:**

- Required fields, positive amount, date order, budget period, and feature enablement are validated.
- A single submitted request appears in the list.
- Available budget is not incorrectly reduced before the configured approval stage.
- Partner B cannot access the request.

#### UI-024 — MDF approval, rejection, and budget override

**Persona:** MDF Reviewer, then reviewer with override authority  
**Steps:** Filter/select requests; approve within budget; reject with comments; attempt over-budget approval without and with override.

**Acceptance criteria:**

- Review details match the selected request and partner budget.
- Approve/reject actions require their granular permissions.
- Over-budget approval is blocked without override authority.
- Override approval succeeds only for the authorized persona and is auditable.
- Budget used/available values update exactly once after approval.

### Stream H — Content Hub

#### UI-025 — Browse, search, filter, and download content

**Persona:** Partner A User  
**Steps:** Browse categories, search by title/description, filter, clear filters, and download visible content.

**Acceptance criteria:**

- Search and category filters return consistent content.
- Inactive content is absent.
- Public and Partner A-eligible restricted content appears; ineligible tier/type content does not.
- Download opens/returns the intended file and records the expected usage/audit event.
- Empty searches show a helpful empty state.

#### UI-026 — Administer content

**Persona:** Internal Administrator/Content Administrator  
**Steps:** Edit title, description, category, visibility, restriction fields, sort order, and active status.

**Acceptance criteria:**

- Saved values persist after refresh.
- Restricted visibility requires coherent tier/type configuration.
- Deactivation removes content from partner results without deleting the source record/file.
- An unauthorized user cannot see or invoke edit/activate actions.

### Stream I — Notifications and alerts

#### UI-027 — Notification bell and unread count

**Persona:** Partner A User  
**Steps:** Open the notification drawer, compare badge count with unread items, mark one as read, and close/reopen the drawer.

**Acceptance criteria:**

- Badge count equals Partner A unread notifications.
- Mark-as-read updates visual state and count without a full-page reload.
- Drawer close via button, Escape, and backdrop behaves consistently.
- Partner B notifications never appear.

#### UI-028 — Dismiss and empty notifications

**Persona:** Partner A User  
**Steps:** Dismiss a notification, refresh, and dismiss remaining test notifications.

**Acceptance criteria:**

- Dismissed items remain absent after refresh.
- A user cannot dismiss another user’s notification by URL or altered client state.
- The final empty state is clear and accessible.

#### UI-029 — Acknowledge operational alert

**Persona:** Operational Manager, then Unprivileged Internal User  
**Steps:** Acknowledge an open alert as manager; attempt the same operation as an unprivileged user.

**Acceptance criteria:**

- Authorized acknowledgement records actor/time and updates status/history.
- Repeated acknowledgement is handled predictably.
- Unauthorized acknowledgement is blocked with a safe message.
- Clearing the underlying condition resolves the alert without losing acknowledgement history.

### Stream J — Analytics and AI

#### UI-030 — Partner scorecard

**Persona:** Partner A User  
**Steps:** Open Partner Scorecard and compare Pipeline, Revenue, Lead Conversion, Deal Win Rate, and MDF Utilisation with prepared data.

**Acceptance criteria:**

- Metrics use Partner A data only and match agreed calculations.
- Zero denominators render as zero/empty—not `NaN`, infinity, or an exception.
- Labels and values remain readable at supported viewports.
- Disabled analytics shows a safe feature state.

#### UI-031 — Executive leaderboard

**Persona:** Authorized executive/channel persona, then Unprivileged Internal User  
**Steps:** Open Partner Leaderboard, verify ranking and totals, then repeat without executive analytics permission.

**Acceptance criteria:**

- Rankings, total revenue, won deals, and active partner counts match source data.
- Ties and zero values render consistently.
- Unauthorized access returns a safe UI error and no cross-partner analytics data.

#### UI-032 — AI provider administration

**Persona:** Internal Administrator with AI authority  
**Steps:** Open AI Provider Administration, inspect providers, test a valid connection, then test the deliberately invalid configuration.

**Acceptance criteria:**

- Provider name, active state, and connection status are correct.
- Valid connection returns success without displaying a secret/token.
- Invalid connection returns a sanitized, actionable error.
- Buttons show progress and prevent duplicate concurrent tests.
- A user without AI configuration permission cannot access the action.

#### UI-033 — AI insights and next-best actions

**Persona:** Partner A User  
**Steps:** Open insight and recommendation surfaces with existing results, no results, disabled AI, and provider failure.

**Acceptance criteria:**

- Existing Partner A insights/actions render with expected priority and rationale.
- Partner B insights never appear.
- No-results and disabled states are distinct from errors.
- Provider failures are sanitized and the rest of the page remains usable.

### Stream K — Partner 360 and record sharing

#### UI-034 — Partner 360 summary

**Persona:** Channel Manager  
**Steps:** Select Partner A and Partner B in Partner 360; inspect commercial metrics, documents, risks, access work, training, blockers, and lifecycle events.

**Acceptance criteria:**

- Changing partner refreshes all sections without stale values.
- Counts and timelines match source records.
- Empty blockers/events have intentional empty states.
- Partner-facing users cannot use the internal Partner 360 interface.

#### UI-035 — Grant partner record access

**Persona:** Authorized share manager  
**Steps:** On a supported record, open Access Manager; select a partner, access level, reason, and optional expiry; grant access.

**Acceptance criteria:**

- Required partner, level, and reason fields are enforced.
- Grant creates one active registry/share entry and appears immediately.
- The target partner gains only the intended record access level.
- Unsupported record types and unauthorized users are blocked safely.
- Duplicate grant attempts do not create uncontrolled duplicate access.

#### UI-036 — Revoke and expire partner access

**Persona:** Authorized share manager  
**Steps:** Revoke one grant while another partner grant remains; create an expiring grant and run/await cleanup.

**Acceptance criteria:**

- Revocation removes only the selected partner’s access.
- Registry status/history remains auditable.
- Other valid shares are unaffected.
- Expired access is removed by cleanup and cannot be used afterward.

### Stream L — Security, resilience, and release regression

#### UI-037 — Cross-partner isolation matrix

**Persona:** Partner A User and Partner B User  
**Steps:** For deals, MDF, leads, notifications, content, dashboards, AI insights, and explicitly shared records, attempt access through lists, search, copied URLs, bookmarks, and browser back history.

**Acceptance criteria:**

- Each partner sees only owned or explicitly shared records.
- Direct URL/API-backed UI access to another partner’s record is denied.
- Denial does not reveal record names, values, IDs, or existence beyond a safe message.
- Revoked/expired access stops working after refresh and in a new session.

#### UI-038 — Persona permission matrix

**Persona:** Every persona in Section 3  
**Steps:** Attempt each major view/action inside and outside the persona’s assigned responsibilities.

**Acceptance criteria:**

- Authorized actions are visible and executable.
- Unauthorized actions are hidden or disabled and also rejected server-side.
- Approval, provisioning, lifecycle, agreement, MDF override, operational alerts, sharing, AI configuration, and analytics remain separately gated.
- Broad Salesforce profile access alone does not unintentionally grant PartnerSync business authority.

#### UI-039 — Error and retry behavior

**Persona:** Relevant internal and partner users  
**Steps:** Simulate offline/network interruption, expired session, failed AI callout, stale record version, double-click, and server error where safely possible.

**Acceptance criteria:**

- Errors use the common safe error UI and never show stack traces or secrets.
- Loading indicators stop after failure.
- Retry does not create duplicate business records or decisions.
- Stale updates are rejected rather than overwriting newer work.
- The user can recover through refresh, retry, cancel, or navigation.

#### UI-040 — Accessibility and browser regression

**Persona:** Partner and internal personas  
**Steps:** Run core journeys in current supported Chrome, Edge, Firefox, and Safari; use keyboard-only navigation, 200% zoom, and a screen reader spot check.

**Acceptance criteria:**

- Core journeys complete in every supported browser.
- Page/component headings, fields, dialogs, tables, status badges, and action controls have accessible names.
- Validation/error messages are programmatically associated with affected controls.
- Color is not the only means of conveying status.
- At 200% zoom, content and primary actions remain usable without loss of information.

## 7. Sprint execution order

| Day/phase              | Scope                               | Exit condition                                                 |
| ---------------------- | ----------------------------------- | -------------------------------------------------------------- |
| 1 — Environment        | UI-001 to UI-003                    | App, health checks, and automation ready                       |
| 2 — Onboarding         | UI-004 to UI-009                    | Applicant-to-provisioning positive and negative paths complete |
| 3 — Partner core       | UI-010 to UI-016                    | Portal, dashboard, and deal submission stable                  |
| 4 — Internal workflows | UI-017 to UI-024                    | Deal, lead, and MDF decisions complete                         |
| 5 — Engagement         | UI-025 to UI-033                    | Content, notifications, analytics, and AI complete             |
| 6 — Governance         | UI-034 to UI-038                    | Partner 360, sharing, isolation, and permissions complete      |
| 7 — Hardening          | UI-039 to UI-040 plus defect retest | Resilience/accessibility complete; blockers closed             |

## 8. Defect severity

| Severity | Definition                                   | Examples                                                                    |
| -------- | -------------------------------------------- | --------------------------------------------------------------------------- |
| Blocker  | Release cannot proceed                       | Cross-partner data exposure, clean login impossible, destructive corruption |
| Critical | Core journey unavailable or authority bypass | Cannot submit/approve; unauthorized approval/provisioning/sharing           |
| Major    | Important function wrong with workaround     | Incorrect KPI, notification state, filter, or audit result                  |
| Minor    | Limited usability/visual issue               | Alignment, wording, non-blocking responsive defect                          |

Any Blocker or Critical defect fails the sprint. Major defects require product-owner disposition and a documented retest plan.

## 9. Exit criteria

- All 40 scenarios executed with evidence.
- All Blocker and Critical defects closed and retested.
- No unresolved cross-partner isolation or permission-boundary defect.
- Core journeys pass on supported desktop browsers and required responsive widths.
- Accessibility checks have no release-blocking issue.
- Installation smoke and packaged Apex tests remain green after any fixes.
- Product Owner, QA Lead, Security Reviewer, and Salesforce Administrator sign off the exact package ID.

## 10. Execution record template

| Field             | Value                                  |
| ----------------- | -------------------------------------- |
| Scenario ID       | UI-\_\_\_                              |
| Tester/persona    |                                        |
| Build/package ID  | `0.1.0.5 / 04tQE00000if8t7YAA`         |
| Browser/viewport  |                                        |
| Started/completed |                                        |
| Test record IDs   |                                        |
| Result            | Pass / Fail / Blocked / Not Applicable |
| Evidence links    |                                        |
| Defect IDs        |                                        |
| Notes             |                                        |
