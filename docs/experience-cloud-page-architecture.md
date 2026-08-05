# PartnerSync: Building the Site — Pages, Shell, and Components

This doc maps every screen-level LWC to the Experience Builder / Lightning App
Builder page it belongs on, which child components it composes, which Apex
controller backs it, and which permission set group has to be assigned before
a user can see it. It also documents the site chrome (`partnerSyncThemeLayout`, `psLogo`,
`navMenu`, `psNotificationBell`, `psFooter`) and how page-to-page
navigation is wired.

## 1. Two audiences, one component library

PartnerSync has two user populations sharing the same LWC bundle and the same
managed package, but they land on different surfaces:

| Audience            | Surface                                                             | Personas (permission set group)                     |
| ------------------- | ------------------------------------------------------------------- | --------------------------------------------------- |
| **Partner-facing**  | Experience Cloud (LWR) site — external, authenticated partner users | `PSG_Partner_User`, `PSG_Partner_Administrator`     |
| **Internal-facing** | Internal Lightning App (App Pages) — your own reviewers/admins      | `PSG_Channel_Manager`, `PSG_Internal_Administrator` |

Every screen component below declares all three targets
(`lightningCommunity__Page`, `lightningCommunity__Default`,
`lightning__AppPage`), so nothing stops you from also dropping an
"internal" screen onto the Experience Cloud site (e.g. giving a channel
manager portal access) or an "partner" screen onto an internal App Page —
but the natural split, and the one the permission set groups assume, is
partner screens on the site and reviewer/admin screens on an internal app.

## 2. Site chrome

**No sidebar.** Reviewed against a real production reference,
[trailheadapps/az-insurance](https://github.com/trailheadapps/az-insurance)
(`force-app/main/default/lwc/customThemeLayout` +
`force-app/main/default/lwc/navigationMenu`) — its Theme Layout uses the
same simple stacked header/main/footer structure as Salesforce's own
official sample, with a horizontal nav bar (hamburger fallback on mobile)
in the header, not a persistent left sidebar. `partnerSyncThemeLayout` and
`psSideNav` originally went a different direction (a 280px sidebar as a
true grid sibling of the content column); that's been reverted —
`psSideNav` is retired (`tools/retired-components/psSideNav/`) and the
Theme Layout is back to the simple structure below.

### `partnerSyncThemeLayout` — the real Experience Builder Theme Layout

This is the component you assign under **Experience Builder → Settings →
Theme Layout**, and it's assigned **per page** — different pages in the same
site can use different Theme Layouts, and you can create more than one. It
wraps every page with three named regions:

```html
<header part="header"><slot name="header"></slot></header>
<main part="main"><slot></slot></main>
<footer part="footer"><slot name="footer"></slot></footer>
```

- All three regions are **bare, empty-by-default slots** — matching both
  Salesforce's official sample (see `tools/metadata-builder/codeSamples/`)
  and az-insurance's own Theme Layout. `header` / `footer` are populated
  once, site-wide (per Theme Layout), from **Experience Builder → Edit
  Theme Layout** — nothing renders until you explicitly drop a component
  in.
- The default (unnamed) `main` slot is populated **automatically and
  separately for every page** — native LWR behavior, not something you
  wire yourself. Whatever components you drop onto a given Builder page
  render into this slot only for that page.
- It also loads `PartnerSync_Theme_Tokens` (the `--ps-*` custom properties)
  onto `:root` via `loadStyle`, which is why individual component CSS files
  can reference `--ps-color-primary` etc. without redeclaring anything — see
  the header comment in
  `force-app/main/default/staticresources/PartnerSync_Theme_Tokens.resource`.
- `.custom-header` (the element wrapping the `header` slot) is
  `display: flex; align-items: center; gap: 1.5rem;`. A `<slot>` with
  assigned nodes renders `display: contents` by default (no box of its
  own), so every component you drop into the `header` region becomes a
  direct flex item of `.custom-header` — that's what makes the
  logo/nav/bell row below work as independent drag-and-drop pieces instead
  of needing one bundled component.

**Recommended header composition:** drop `c-ps-header` (`PartnerSync
Header`) into the `header` region — a single component that wraps
`c-ps-logo`, `c-nav-menu`, and `c-ps-notification-bell` as one `.ps-header`
flex row, so there's exactly one drag-and-drop instead of three. It
forwards its own configurable properties straight through to the two
children that need them (logo URL/wordmark/home page to `psLogo`; menu
name/button label/button redirect page to `navMenu` — `psNotificationBell`
takes no configuration). Each child is still `flex-shrink: 0` except
`navMenu`, which is `flex: 1 1 auto` and centers its item list in the
remaining space, so the row lays out as logo (left) / nav (centered, grows
to fill) / bell (right). `psLogo`, `navMenu`, and `psNotificationBell`
remain individually exposed too, if a page ever needs to drop just one of
them on its own.

### `psLogo` — brand mark, drop into the `header` region

`psLogo` (`c-ps-logo`) is a small, admin-configurable brand mark: an
optional image (`Logo Image URL` — a static resource path or Content
Asset URL) falling back to a text wordmark when left blank, wrapped in a
link that navigates to a configurable `Home Page Name` via
`NavigationMixin` (`comm__namedPage`). Leave `Home Page Name` blank to
render a non-clickable mark. When an image is set it's rendered
`aria-hidden` with empty `alt` — the link itself carries the accessible
name via `Wordmark Text`, so there's exactly one accessible label per
logo, not two competing ones.

### `navMenu` — the primary navigation, drop into the `header` region

`navMenu` (`c-nav-menu`) renders a real Salesforce **Navigation Menu**
(Setup → Digital Experiences → Navigation Menus → a `NavigationLinkSet`) —
horizontal, admin-configurable (add/reorder/nest/restrict-by-login without
touching code), and closely modeled on az-insurance's own
`navigationMenu` component (same wire adapters and general approach).

- Backed by `NavMenuItemsController.getNavigationMenuItems` (queries the
  standard `NavigationLinkSet`/`NavigationMenuItem` objects) and
  `NavigationPickList` (a `VisualEditor.DynamicPickList` that lists your
  site's Navigation Menu Linksets in the Builder property panel).
  `NavigationPickList.getValues()` must **not** filter its query by
  `Network.getNetworkId()` — Dynamic Picklist classes run in Experience
  Builder's admin/configuration context, where the current network doesn't
  reliably resolve, so a `NetworkId` filter silently returns zero rows and
  the property panel shows every stored value as "This is not a valid
  option." (Confirmed against az-insurance's real, working
  `NavigationLinkSetPickList`, which has no such filter.) The runtime query
  in `NavMenuItemsController` is different — it runs in true site-visitor
  context, so filtering by `NetworkId` there is correct and necessary.
- `navMenu` only resolves the Navigation Menu tree (querying, building the
  parent/child structure via `ParentId`, Draft/Live and access filtering).
  Rendering an individual item — turning a `NavigationMenuItem` row into a
  clickable link with the right `href` and click-navigation — is delegated
  to the sibling component **`navMenuItems`** (`c-nav-menu-items`,
  `fqn="navMenuItem"`), one instance per item, passed the raw item via
  `item` and an optional `variant="submenu"` for dropdown children. Do not
  reimplement link/href resolution directly in `navMenu` — `navMenuItems`
  already handles the three real `NavigationMenuItem.Type` values
  correctly: `SalesforceObject` (`Target` is an object API name, routed via
  `standard__objectPage` with `DefaultListViewId` as the list view filter),
  `InternalLink` (`Target` is a raw relative path, prefixed with
  `basePath` and routed via `standard__webPage`), and `ExternalLink`
  (`Target` is a full URL, also `standard__webPage`) — resolved to a real
  `href` via `NavigationMixin.GenerateUrl` and navigated via
  `NavigationMixin.Navigate` on click. `navMenuItems` dispatches a
  `navigation` event on click so `navMenu` can close the mobile hamburger
  menu / collapse an open submenu.
- Supports up to one level of nested/dropdown items (`ParentId`), and only
  shows items whose `AccessRestriction` is `None`, or `LoginRequired` for
  authenticated (non-guest) visitors via `@salesforce/user/isGuest` — any
  other value (e.g. `HideAlways`) is hidden. `None`, not `ShowAlways`, is
  the real stored value for "always visible" (confirmed against
  az-insurance's reference implementation).
- Automatically shows Draft (unpublished) items while previewing in
  Experience Builder and Live (published) items on the real site, via the
  `CurrentPageReference` wire adapter's `state.app === "commeditor"` check.
- Configurable in Builder: `Navigation Menu Name` (the Linkset,
  datasource-driven picklist), plus an optional `Button Label` /
  `Button Redirect Page Name` for a trailing call-to-action button.
- Has its own responsive hamburger toggle for mobile — no separate mobile
  handling needed elsewhere in the Theme Layout.

### `psNotificationBell` — drop into the `header` region

`psNotificationBell` (`c-ps-notification-bell`) is the unread-count bell:
an icon button with a badge (subscribes to
`/event/NotificationCreatedEvent__e` via `empApi` for live updates, plus
`NotificationController.getUnreadCount` on load), opening a drawer on
click that wraps `c-ps-notification-center`. No configurable properties —
just drag `PartnerSync Notification Bell` into the `header` region. It's
also composed directly inside `psHeader` and `psTopNav` (below), so the
same component backs all three patterns.

### `psTopNav` — an alternative, simpler header occupant

`psTopNav` (branding text + `c-ps-notification-bell`) is a lighter-weight,
single-drop alternative to `psHeader` (above) — just static branding and
the notification bell, no configurable Navigation Menu. Independently
exposed with `targetConfigs` for `eyebrow` (default `Partner Portal`) and
`title` (default `PartnerSync Accelerator`); drag `PartnerSync Top
Navigation` into the `header` region the same way as `psHeader`. (Use one
header pattern or the other, not a mix — `psHeader` if you want a real
image logo and configurable navigation items, `psTopNav` if a text
branding bar is enough and navigation lives elsewhere, e.g. links within
each page itself.)

Remember `:host { display: block; height: 100%; }` on any new region
occupant you write — LWC custom elements default to `display: inline`,
which silently breaks a component meant to fill a flex/grid container.
`psTopNav.css` already has it; this was a real bug in the retired
`psSideNav.css`, which is missing it (see its README for detail).

### `psFooter` — drop into the Theme Layout's `footer` region

Copyright line + an optional real Navigation Menu-backed link row — modeled
on trailheadapps/az-insurance's `footer`/`footerList`/`footerMenuItem` trio
rather than the hardcoded `href="#"` placeholders this used to ship with.
`companyName` is a Builder-configurable `@api` property (defaults to
`PartnerSync`); the copyright year is computed at render time so it never
needs updating by hand.

The link row itself is `footerMenuName` (Builder property, same
`apex://NavigationPickList` datasource as `navMenu`'s `menuName`) — pick an
existing Navigation Menu Linkset (Setup → Digital Experiences → Navigation
Menus) and `psFooter` renders it via `c-ps-footer-list`, which wires
`NavMenuItemsController.getNavigationMenuItems` (the same controller
`navMenu` uses) and delegates each item to `c-nav-menu-items` for href
resolution/click navigation — no separate footer-item component, since
footer links never have submenus and `c-nav-menu-items`'s "default" variant
already handles that case. Items are filtered the same way as `navMenu`:
`AccessRestriction: None` always shows, `LoginRequired` only shows for
authenticated (non-guest) visitors via `@salesforce/user/isGuest`. Leave
`footerMenuName` blank to hide the link row entirely (e.g. before you've
built a Privacy/Terms/Support page to point it at).

## 3. Partner-facing pages (Experience Cloud site)

Build one Experience Builder page per row, drop the listed component
directly into the page's main region, and set page-level audience/access to
require the listed permission set group (**Experience Builder → Settings →
Pages → [page] → Audience Targeting**, or restrict at the permission-set
level if you're not using audiences).

| Page           | Drop this component           | Apex controller                                                                     | Requires                                                                                                          |
| -------------- | ----------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Home           | `c-ps-home-dashboard`         | `PartnerPortalController`                                                           | `PSG_Partner_User`                                                                                                |
| My Deals       | `c-ps-deal-list`              | `DealRegistrationController` (`getMyDeals`)                                         | `PSG_Partner_User`                                                                                                |
| Register Deal  | `c-ps-deal-registration-form` | `DealRegistrationController` (`getEligibleOpportunities`, `createDealRegistration`) | `PSG_Partner_User`                                                                                                |
| Assigned Leads | `c-ps-partner-leads`          | `LeadDistributionController`                                                        | `PSG_Partner_User` or `PSG_Partner_Administrator`                                                                 |
| MDF            | `c-ps-mdf-workspace`          | `MDFController`                                                                     | `PSG_Partner_User`                                                                                                |
| Content Hub    | `c-ps-content-hub`            | `PartnerContentController`                                                          | `PSG_Partner_User`                                                                                                |
| AI Insights    | `c-ps-ai-insight-panel`       | `PartnerAIController`                                                               | `PSG_Partner_User` (bundles `PartnerSync_AI_User`) — also gated at runtime by `TenantConfigService.isAiEnabled()` |
| Leaderboard    | `c-ps-partner-leaderboard`    | `AnalyticsController`                                                               | `PSG_Partner_Administrator` or `PSG_Partner_User` (both bundle `PartnerSync_Analytics_User`)                      |

Notes:

- **Assigned Leads is now available to every partner user.**
  `LeadDistributionController` was previously only granted to
  `PartnerSync_Partner_Admin` — added to `PartnerSync_Partner_User` too,
  since `psHomeDashboard`'s assigned-lead count and "View Leads" quick
  action assume every partner user can reach it, and the field-level
  permissions on `Lead` were already present in `PartnerSync_Partner_User`
  (only the class access was missing).
- **Register Deal now has a real screen.** `c-ps-deal-registration-form`
  lets a partner pick from their eligible Opportunities (ones tied to their
  partner account that don't already have a `Deal_Registration__c`) and
  submit `DealRegistrationController.createDealRegistration`.
  `DealRegistrationService` now also rejects registering the same
  Opportunity twice server-side (`hasExistingRegistration`), independent of
  the UI. Note that this registers an **existing** Opportunity — it does not
  create a brand-new Opportunity or upload a new deal from scratch; there
  was no Opportunity-creation flow to build against, so this matches the
  original Apex contract (`createDealRegistration(opportunityId, ...)`).
- **My Deals' "Register Deal" button now navigates to the Register Deal
  page.** `c-ps-deal-list` previously dispatched a `newdeal` custom event
  with no listener anywhere in the app — dead on click. It now uses
  `NavigationMixin` to navigate to a configurable `registerDealPageName`
  (defaults to `Register-Deal`, set via the component property in Experience
  Builder if your page uses a different API name), mirroring how
  `c-ps-deal-registration-form`'s own "View My Deals" button already
  navigates back to `My-Deals`. The row-level "View" button (`opendeal`
  event) is still unwired — there's no Deal Detail page/component built yet.

### Public pages (no login required)

One page doesn't fit the audience/permission-set model above because it runs
**before** a partner has an account at all.

| Page                      | Drop this component             | Apex controller                                      | Requires                                                                        |
| ------------------------- | ------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| Apply to Become a Partner | `c-ps-partner-application-form` | `PartnerApplicationController` (`submitApplication`) | Guest User profile access to the class and to `Partner_Application__c` (create) |

Put this on a Guest-accessible Experience Builder page (**Audience Targeting**
set to allow unauthenticated visitors, or no audience restriction at all).
It writes a `Partner_Application__c` record — not an Account/Contact/User —
gated behind `TenantConfigService.isOnboardingEnabled()`
(`Tenant_Config__mdt.Enable_Onboarding__c`). Submissions land in the
internal **Partner Applications** review queue (§4); approving one there is
what actually provisions the partner's `Account` + primary `Contact`
(`PartnerOnboardingService.approveApplication`) — the public form itself
never creates partner records directly.

Unlike every other component in this app, this one needs Guest User access
granted explicitly: Setup → Digital Experiences → your site → Administration
→ **Preferences** (or Guest User Profile → Apex Class Access) to expose
`PartnerApplicationController`, plus object/field permissions on
`Partner_Application__c` (Create + Edit on the fields the form submits) for
the Guest User Profile. This is a deliberate, narrow exception to "private by
default" — worth a second look before enabling in a real org, since it's the
one place in PartnerSync where an unauthenticated visitor can write data.

## 4. Internal-facing pages (Lightning App / App Page)

Build these as tabs/pages on an internal Lightning App (**Setup → App
Manager → New Lightning App**, or as standalone App Pages via **Lightning App
Builder**). Assign the permission set group per row instead of Experience
Builder audience targeting.

| Page                   | Drop this component               | Apex controller                                                                                                                    | Requires                                                                                                                                                                     |
| ---------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Home                   | `c-ps-internal-dashboard`         | `InternalPortalController`                                                                                                         | `PSG_Channel_Manager` or `PSG_Internal_Administrator`                                                                                                                        |
| Deal Review            | `c-ps-deal-review-workspace`      | `DealReviewController`                                                                                                             | `PSG_Channel_Manager` or `PSG_Internal_Administrator` (both grant `DealReviewController`)                                                                                    |
| MDF Review             | `c-ps-mdf-workspace`              | `MDFController`                                                                                                                    | `PSG_Channel_Manager` (via `PartnerSync_MDF_Reviewer`) or `PSG_Internal_Administrator` (same)                                                                                |
| Notification Center    | `c-ps-notification-center`        | `NotificationController`                                                                                                           | `PSG_Channel_Manager` or `PSG_Internal_Administrator`                                                                                                                        |
| Content Administration | `c-ps-content-admin`              | `PartnerContentController` (`getAllContent`, `saveContent`)                                                                        | `PSG_Channel_Manager` or `PSG_Internal_Administrator` (both bundle `PartnerSync_Content_Admin`)                                                                              |
| AI Provider Admin      | `c-ps-ai-provider-admin`          | `AIInsightController` (`getProviders`, `testProviderConnection`)                                                                   | `PSG_Internal_Administrator` only (`PartnerSync_AI_Admin`)                                                                                                                   |
| Executive Analytics    | `c-ps-partner-leaderboard`        | `AnalyticsController`                                                                                                              | Add `PartnerSync_Executive_User` for `PartnerSync_View_Executive_Analytics` / `PartnerSync_Export_Executive_Reports` custom permissions on top of the analytics access above |
| Partner Applications   | `c-ps-partner-application-review` | `PartnerApplicationController` (`getPendingApplications`, `getApplicationDetail`), `PartnerApprovalController` (`processDecision`) | `PSG_Channel_Manager` or `PSG_Internal_Administrator` (via `PartnerSync_Channel_Manager` / `PartnerSync_Internal_Admin`)                                                     |

`psDealReviewWorkspace` and `psMdfWorkspace` reuse the exact same components
whether you place them on the internal app or (in theory) the partner site —
access is enforced by the permission set, not by the component knowing which
surface it's on.

**`c-ps-internal-dashboard` is the internal analog to `psHomeDashboard`.**
Backed by `InternalPortalController.getDashboard()` →
`InternalDashboardService` → three metric counts: pending deal reviews
(`DealReviewService.getReviewQueue()` filtered to the pending statuses,
gated behind `PartnerPermissionService.canViewAllDeals()`), pending
MDF reviews (`MDFSelector.selectReviewQueue()`, gated behind
`canViewAllMdf()`), and unread notifications
(`NotificationSelector.countUnreadForUser`, ungated — every internal user
can see their own count). Each section degrades to `0` rather than throwing
if the current user lacks that specific permission, same pattern as
`PartnerDashboardService`. Its four Quick Action buttons navigate via
`NavigationMixin`'s `standard__navItemPage` type (not `comm__namedPage` —
that's Experience-Cloud-only) to configurable `@api` tab-name properties
(`dealReviewTabName`, `mdfReviewTabName`, `notificationsTabName`,
`contentAdminTabName`) — **set these to match your internal Lightning App's
actual tab API names**.

**Content Administration and AI Provider Admin now have real screens.**

- `c-ps-content-admin` lists every `Partner_Content__c` record (active and
  inactive), lets an admin toggle active/inactive inline, and edit title,
  description, category, visibility, partner tier/type, featured, and sort
  order in a modal (`PartnerContentService.saveContent`, gated by the new
  `PartnerPermissionService.canManageContent()` / `PartnerSync_Content_Admin`
  check). It does **not** support uploading a brand-new content asset from
  scratch — that needs a file-upload flow (`ContentVersion`/
  `Content_Document_Id__c`), which is a separate, larger feature; today it
  only edits existing records.
- `c-ps-ai-provider-admin` lists every `AI_Provider_Config__mdt` record
  merged with its latest `AI_Configuration__c` connection-status row (via
  the new `AIProviderAdminService.getProviders()` /
  `AIProviderSelector`), with a "Test Connection" button per provider
  wired to the existing `AIInsightController.testProviderConnection`. It
  only surfaces status — editing the underlying `AI_Provider_Config__mdt`
  connection settings (Named Credential, model, temperature, etc.) still
  happens via Setup, which is appropriate since those are Custom Metadata
  records.

**Bonus fix — MDF request submission was silently broken.** Found while
building the screens above: `psMdfWorkspace.handleRequestCreated` only
refreshed the request list token and never actually called
`MDFController.submitRequest` — the campaign name/amount/justification a
partner typed into `psMdfRequestForm` were discarded. The form was also
missing `requestType`, which `MDFDomain.validateSubmit` requires (would have
failed validation even if the call had been wired). Both are fixed now:
`psMdfRequestForm` collects `requestType` (Event/Webinar/Digital
Advertising/Content Syndication/Direct Mail/Other, matching
`MDF_Request__c.Campaign_Type__c`'s picklist) and maps its free-text field to
the real `campaignDescription` DTO field instead of a `businessJustification`
field that didn't exist on `MDFRequestDTO`; `psMdfWorkspace` now awaits
`submitRequest`, shows `c-ps-error-panel` on failure, and only refreshes the
list on success.

**Partner Applications now has a real screen, and the backend it's built on
had a live bug.** `PartnerApplicationController`/`PartnerApprovalController`
already existed (public submission + approve/reject), but nothing called
them — `c-ps-partner-application-review` is the first UI on top. Same
split-pane/stamp pattern as Deal Review: a ruled queue on the left (search by
company name), the selected application's full detail on the right, and a
rotated ink stamp once a decision is made instead of another colored badge.
Approving an application is what actually creates the partner's `Account` +
primary `Contact` (`PartnerOnboardingService.approveApplication`).

Two real bugs surfaced while wiring this up, both now fixed:
`PartnerApplicationDomain.buildSubmittedRecord` never set `Partner_Application__c.Name`
(a required plain Text field, not an autonumber) — every public submission
would have failed at insert with a required-field error. Separately,
`toResultDTO` read the application number from `Name` instead of the real
autonumber field, `Application_Number__c` — fixed, and `Application_Number__c`
is now included in every SOQL query that needs it
(`PartnerApplicationSelector`). The review screen also needed two new DTOs
(`PartnerApplicationListDTO`, `PartnerApplicationDetailDTO`) since the
existing `PartnerApplicationResultDTO` only carried an id/number/status triple
— fine for a public submission confirmation, not enough for an internal
reviewer to actually see who they're deciding on.

## 5. Full component inventory

### Screen-level (`isExposed=true` with real targets — placeable directly on a page)

| Component                    | Purpose                                                   | Children it composes                                                      |
| ---------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------- |
| `psHomeDashboard`            | Partner home / dashboard                                  | `psDashboardMetricCard`, `psEmptyState`, `psErrorPanel`, `psLoadingState` |
| `psInternalDashboard`        | Internal home / dashboard                                 | `psDashboardMetricCard`, `psEmptyState`, `psErrorPanel`, `psLoadingState` |
| `psPartnerLeads`             | Assigned leads, accept/reject/convert                     | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psDealList`                 | Partner's own deal registrations                          | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psDealRegistrationForm`     | Register an eligible Opportunity as a deal                | `psLoadingState`, `psErrorPanel`, `psEmptyState`                          |
| `psContentHub`               | Browse/search/download content                            | `psContentCard`, `psEmptyState`, `psErrorPanel`                           |
| `psMdfWorkspace`             | MDF requests + budget (partner and reviewer)              | `psMdfBudgetCard`, `psMdfList`, `psMdfRequestForm`                        |
| `psDealReviewWorkspace`      | Internal deal review queue                                | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psAiInsightPanel`           | AI-generated partner insights                             | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psPartnerNextBestActions`   | AI next-best-action suggestions                           | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psPartnerLeaderboard`       | Analytics / performance rankings                          | `psDashboardMetricCard`, `psEmptyState`, `psErrorPanel`, `psLoadingState` |
| `psNotificationCenter`       | Full notification list                                    | _(none currently)_                                                        |
| `psContentAdmin`             | Internal: manage content assets                           | `psModal`, `psEmptyState`, `psErrorPanel`, `psLoadingState`               |
| `psAiProviderAdmin`          | Internal: AI provider connection status                   | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psPartnerApplicationForm`   | Public: apply to become a partner (no login)              | `psErrorPanel`                                                            |
| `psPartnerApplicationReview` | Internal: review/decide pending partner applications      | `psEmptyState`, `psErrorPanel`, `psLoadingState`                          |
| `psHeader`                   | Recommended header-region drop (site chrome)              | `psLogo`, `navMenu`, `psNotificationBell`                                 |
| `navMenu`                    | Admin-configured horizontal Navigation Menu (site chrome) | _(none currently)_                                                        |
| `psLogo`                     | Brand mark / wordmark, links to Home (site chrome)        | _(none currently)_                                                        |
| `psNotificationBell`         | Unread-count bell + notification drawer (site chrome)     | `psNotificationCenter`                                                    |
| `psFooter`                   | Site footer (copyright + Navigation Menu-backed links)    | `psFooterList`                                                            |
| `psFooterList`               | Internal: renders a footer Navigation Menu's items        | `navMenuItems`                                                            |
| `psTopNav`                   | Branding + notification bell (site chrome)                | `psNotificationBell`                                                      |

`psContentCard`, `psErrorPanel`, and `psDrawer` also declare
`isExposed=true` with full targets even though today they're only ever used
as children — that just means Experience Builder _would_ let you drop them
standalone (harmless, just not how they're actually used). `psLogo` and
`navMenu` are the same shape now that `psHeader` wraps them — both remain
individually droppable, but `psHeader` is the recommended path (§2).
`psNotificationBell` is reused three ways: standalone header-region drop,
as a child of `psHeader`, and as a child of `psTopNav`.

### Child-only (`isExposed=false` — only render inside another component's template)

| Component               | Used by                                       |
| ----------------------- | --------------------------------------------- |
| `psDashboardMetricCard` | `psHomeDashboard`, `psPartnerLeaderboard`     |
| `psEmptyState`          | Most screen components (empty-state fallback) |
| `psLoadingState`        | Most screen components (loading fallback)     |
| `psMdfBudgetCard`       | `psMdfWorkspace`                              |
| `psMdfList`             | `psMdfWorkspace`                              |
| `psMdfRequestForm`      | `psMdfWorkspace`                              |

### Not currently composed anywhere (exist, but no parent references them)

`psAiInsightCard`, `psStatusBadge`, `psFilterPanel`, `psSearchBar`,
`psPartnerKpiDashboard`, `psDrawer`. These are real, working
components — they're just spare parts today. If you're building a new
screen and need a card/filter/search, check here first before writing
a new one; if you're auditing for dead code, these are the ones to look at
(not necessarily _remove_ — several look like they're meant for a future
compare-partners or drill-down view that hasn't been built).
`psModal` is no longer on this list — `psContentAdmin`'s edit dialog uses it.

### Retired

`psAppShell` (sidebar + topbar bundle) has been moved to
`tools/retired-components/psAppShell/` — it's no longer deployed. It never
actually worked as a single dropped component either on the site or on an
internal App Page, since Builder tools can't compose a child into another
dropped component's internal slot — see the README in that folder for the
full explanation.

`psSideNav` (hardcoded 6-item vertical sidebar) has been moved to
`tools/retired-components/psSideNav/` — the site uses a horizontal
`navMenu`/`psTopNav` header instead (§2), matching both Salesforce's
official Theme Layout sample and az-insurance's real production pattern.
See the README in that folder for the full explanation.

`psAiInsightCard` and `navMenuItems` also have `isExposed=true` but declare
**no** `<targets>` at all in their `js-meta.xml`, so even though they're
"exposed," neither is currently placeable anywhere via the Builder UI.
`navMenuItems` (`fqn="navMenuItem"`) is a child-only building block used
exclusively by `navMenu` (§2) to render a single `NavigationMenuItem` —
see `navMenu`'s description above for how the two compose. It isn't a
Dynamic Navigation Menu Apex data source (that's `NavMenuItemsController.cls`
/ `NavigationPickList.cls`) and doesn't belong on a page at all.

## 6. Step-by-step: adding a new partner-facing page

1. **Experience Builder → Pages → New Page**, pick a template with a single
   main content region (avoid multi-column templates unless the screen
   component is built for one — none of these are).
2. Drag the screen component (e.g. `PartnerSync Content Hub`, matching the
   `masterLabel` in its `js-meta.xml`) into the main region. Don't add its
   children (`psContentCard` etc.) separately — the screen component renders
   them itself from the data it fetches.
3. Set the page's **Audience/Access** so only the intended permission set
   group can reach it (Setup → Digital Experiences → your site → Audience
   Targeting, or restrict via profile/permission set if you're not using
   Audiences).
4. Add the page to the site's Navigation Menu (via `navMenu`'s configured
   Linkset, or the standard site Navigation Menu setup), and/or set
   `psHomeDashboard`'s matching page-name property (§2) to this page's
   actual API name so the Quick Action buttons navigate to it correctly.
5. Publish.

## 7. Step-by-step: adding a new internal-facing page

1. **Setup → App Manager → New Lightning App** (or reuse an existing
   internal app), add a new **Lightning Page** (App Page) from **Lightning
   App Builder**.
2. Drag the screen component in — same components, same rule about not
   manually placing its children.
3. Assign the page (or its tab) via the internal app's **User Profiles /
   Permission Sets** access list, matching the permission set group from §4.
4. Add as a tab on the internal app's navigation.
