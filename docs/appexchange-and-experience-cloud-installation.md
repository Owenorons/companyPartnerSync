# PartnerSync AppExchange and Experience Cloud Installation Model

This document explains what a customer receives when purchasing PartnerSync through Salesforce AppExchange, what the managed second-generation package installs, and how the optional Experience Cloud portal is configured.

## Product boundary

PartnerSync consists of two related layers:

| Layer                        | Delivery mechanism                                                           | Customer outcome                                                                                                                                    |
| ---------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| PartnerSync core application | Managed second-generation package (2GP) installed from AppExchange           | Installs the namespaced data model, Apex, Lightning components, automation, permissions, configuration metadata, and internal Lightning application |
| PartnerSync partner portal   | Experience Builder template or Lightning Bolt Solution plus subscriber setup | Creates the starting point for a customer-owned Experience Cloud site using the components supplied by the core package                             |

The AppExchange purchase does not include Salesforce Experience Cloud licences. It also cannot activate a Digital Experiences domain or publish a production site on the customer's behalf. Those resources belong to the subscriber's Salesforce org and remain under the subscriber's control.

## What the managed package installs

The PartnerSync `04t...` package version installs the contents of `force-app`, including supported package metadata such as:

- namespaced custom objects, fields, relationships, validation, and Custom Metadata Types;
- Apex services, controllers, asynchronous processing, and package-isolated tests;
- Lightning Web Components used by internal users and Experience Builder pages;
- flows and other supported automation;
- custom permissions, permission sets, and permission-set groups;
- Lightning tabs and the internal PartnerSync Lightning application; and
- configuration defaults that are safe and portable across subscriber orgs.

After installation, licensed internal Salesforce users can use the PartnerSync core application once an administrator assigns the appropriate PartnerSync permission-set group and completes the core setup.

## What the managed package does not install

The following items are subscriber-specific or require a separate Experience Cloud delivery mechanism:

- an activated Digital Experiences domain;
- a customer-specific Experience Cloud site and its published URL;
- Experience Cloud user licences;
- subscriber users, profiles, role hierarchy, account relationships, and licence assignments;
- customer branding, legal text, navigation choices, and production content;
- Named Credential or External Credential secrets and principals;
- subscriber-specific sharing sets, sharing rules, and access mappings;
- production endpoints, identity-provider configuration, certificates, and keys; and
- a pre-published site workspace.

Source examples and development metadata for these concerns live in `org-config`. That directory is not a second package and must not be deployed wholesale into a customer org. Each item must be reviewed, parameterised, or converted into a supported install-time asset before customer delivery.

## Recommended AppExchange offer

PartnerSync should be presented as a core application with an optional portal accelerator.

### Core PartnerSync application

The primary AppExchange listing installs the managed 2GP package. This is the system of record for upgrades, namespace ownership, licence management, and security review.

The listing should state that the internal application can operate without Experience Cloud, subject to the required Salesforce edition and user licences.

### PartnerSync Experience template

The portal experience should be distributed as a supported Experience Builder template or Lightning Bolt Solution. A Lightning Bolt Solution can include an exported Experience Builder template, pages, flows, and a custom application, and Salesforce supports distributing such a solution through AppExchange.

Installing a template does not immediately publish a portal. It gives the subscriber administrator a PartnerSync starting template when creating or configuring an Experience Cloud site. The administrator still owns the site, domain, branding, licences, access model, and publication decision.

Salesforce references:

- [Lightning Bolt for Salesforce: Build Once, Then Distribute and Reuse](https://help.salesforce.com/s/articleView?id=experience.community_builder_export_overview.htm&language=en_US&type=5)
- [Package and Distribute a Lightning Bolt Solution](https://help.salesforce.com/s/articleView?id=experience.community_builder_export_package.htm&language=en_US&type=5)
- [Requirements for Distributing Lightning Bolt Solutions](https://help.salesforce.com/s/articleView?id=experience.community_builder_export_guidelines.htm&language=en_US&type=5)
- [Export and Packaging Considerations for Lightning Bolt Solutions](https://help.salesforce.com/s/articleView?id=sf.community_builder_export_considerations.htm&language=en_US&type=5)

## Customer purchase and installation journey

### 1. Confirm prerequisites before purchase

The customer confirms that their Salesforce org has:

1. a PartnerSync-supported Salesforce edition;
2. sufficient internal Salesforce licences for administrators and internal PartnerSync users;
3. Experience Cloud entitlements and suitable external-user licences if the portal is required;
4. authority to enable Digital Experiences and configure a domain; and
5. an administrator who can install packages, assign permissions, configure sharing, and publish a site.

The AppExchange listing and order form should make the portal prerequisites visible before purchase.

### 2. Purchase PartnerSync

The customer purchases PartnerSync under the chosen commercial terms. PartnerSync package licensing and Salesforce platform licensing are separate:

- the PartnerSync charge grants use of the PartnerSync product; and
- Salesforce charges and grants the underlying Salesforce and Experience Cloud licences.

PartnerSync must not represent its product fee as including Salesforce Experience Cloud unless a separate commercial agreement explicitly provides those licences.

### 3. Install the managed package

The subscriber administrator selects **Get It Now** on AppExchange and chooses the target org. Salesforce installs the released `04t...` PartnerSync version.

For a production installation, the administrator should:

1. verify the target production org and installation user;
2. review the requested component access;
3. install for administrators only unless the release instructions specify otherwise;
4. wait for Salesforce's installation-complete notification; and
5. open the PartnerSync setup experience.

Installing for administrators first avoids granting incomplete access before permission sets and sharing have been configured.

### 4. Run PartnerSync core setup

The PartnerSync setup experience should guide the administrator through:

1. package version and feature checks;
2. assignment of internal permission-set groups;
3. required Custom Metadata configuration;
4. optional integration configuration;
5. sample-data or production-data readiness checks; and
6. an internal-user smoke test.

Schedule the required operational automation once after installation:

```sh
sf apex run \
  --file scripts/apex/schedule-partnersync-operations.apex \
  --target-org <subscriber-org-alias>
```

The Setup and Health Check page reports any missing or inactive PartnerSync
jobs and lets an authorised PartnerSync administrator configure them directly.
The CLI command is an alternative for controlled or automated implementations.
These jobs enforce lifecycle governance, scan operational alerts, reconcile
provisioning, expire deal protection, and revoke expired sharing.

For controlled test or implementation environments, the repository provides a
guarded orchestration helper:

```sh
PARTNER_SYNC_TARGET_ORG=<subscriber-org-alias> \
PARTNER_SYNC_EXPECTED_PACKAGE_VERSION=<installed-04t-version-id> \
PARTNER_SYNC_DEPLOY_ORG_CONFIG=false \
PARTNER_SYNC_RUN_POST_INSTALL_TESTS=true \
./scripts/post-install.sh
```

It requires an explicit target, assigns the running internal user the packaged
administrator group, schedules the operational jobs, runs a namespace-safe
smoke check, and optionally runs all installed-org tests. Subscriber metadata
under `org-config` remains disabled unless an implementation owner has reviewed
it and deliberately sets `PARTNER_SYNC_DEPLOY_ORG_CONFIG=true`.

This helper does not make customer governance decisions: credentials and
secrets, Sharing Sets, Experience Cloud licensing/domain/site publication, and
external-user creation remain manual, authorised subscriber actions.

Secrets must be entered directly into Salesforce credential facilities. They must never be supplied as package metadata, sample files, or support tickets.

At this point, customers who purchased only the internal application can begin using PartnerSync without creating an Experience Cloud site.

### 5. Enable Experience Cloud when required

For the optional portal, the subscriber administrator:

1. confirms that the org owns the required Experience Cloud licences;
2. enables Digital Experiences in Setup;
3. chooses and registers the org's Digital Experiences domain;
4. confirms the external-user licence model and account/role design; and
5. confirms who is authorised to create, configure, and publish the site.

The domain is a subscriber decision and can affect every Experience Cloud site in the org. PartnerSync must not select or change it silently.

### 6. Create the PartnerSync site

The administrator installs or accesses the PartnerSync Experience template and creates a site from it. The template should reference the namespaced LWCs installed by the core package.

The administrator then reviews:

- page structure and component visibility;
- navigation and audience targeting;
- theme, logos, colours, legal notices, and accessibility;
- login, registration, password, and identity-provider behaviour;
- object list views and navigation links that may reset during template export;
- supported desktop, tablet, and mobile layouts; and
- strict Content Security Policy compatibility.

Template export has limitations. Only supported Experience Builder assets and settings are portable, so the customer setup process must not assume the entire source site's administration workspace was reproduced.

### 7. Configure external-user security

Before creating production users, the administrator configures and verifies:

1. the external-user licence type;
2. PartnerSync external permission sets or permission-set groups compatible with that licence;
3. account, contact, and external-user relationships;
4. organisation-wide defaults;
5. sharing sets, sharing rules, role-based sharing, or other approved access controls;
6. Apex class and component access delivered through permission sets; and
7. least-privilege access for every PartnerSync object and action.

Profiles should contain only unavoidable licence- or login-level configuration. PartnerSync capability access should be managed primarily through packaged permission sets and permission-set groups so upgrades remain maintainable.

Follow [Post-install sharing setup](post-install-sharing-setup.md) for the PartnerSync sharing model.

### 8. Configure integrations

If the customer uses signature, AI, document, email, or other external services, the administrator configures the required Named Credentials and External Credentials in the subscriber org.

The package can install safe credential definitions when supported, but the subscriber must provide:

- endpoints appropriate to its environment;
- authentication principals;
- secrets, certificates, or tokens;
- permission-set mappings to credential principals; and
- any required remote-system allow-listing.

No working production secret should exist in this repository or in an AppExchange package.

### 9. Validate before publication

The customer or implementation partner validates at least:

- internal administrator access;
- one representative external partner user;
- record isolation between two unrelated partner accounts;
- onboarding and approval flows;
- deal, MDF, content, and document journeys enabled for that customer;
- email and integration behaviour;
- error handling and support information;
- desktop and mobile layouts; and
- logout, password, registration, and disabled-user behaviour.

Subscriber integration tests under `org-config/main/default/classes` can be adapted and deployed into an implementation or test org after the managed package and required subscriber configuration exist. They are not part of the managed package's isolated coverage gate.

### 10. Publish and hand over

Only after acceptance testing should an authorised subscriber administrator publish the Experience Cloud site. The handover record should include:

- installed PartnerSync `04t...` version;
- site name and URL;
- selected template version;
- enabled features and integrations;
- assigned permission-set groups;
- security and sharing approvals;
- operational owners and support contacts; and
- rollback or site-unpublish procedure.

## Suggested setup-wizard behaviour

A packaged PartnerSync Setup Wizard should detect and report prerequisites without making high-impact subscriber decisions automatically.

| Check                        | Wizard behaviour                                                                        |
| ---------------------------- | --------------------------------------------------------------------------------------- |
| Core package metadata        | Verify required metadata and display the installed version                              |
| Internal permissions         | Recommend and assign only after explicit administrator confirmation                     |
| Experience Cloud entitlement | Detect availability and explain the required Salesforce licensing when unavailable      |
| Digital Experiences domain   | Report whether configured; link the administrator to the relevant Setup page            |
| Site template                | Explain how to install/select the PartnerSync template and create the site              |
| External permissions         | Validate permission-set compatibility with the selected external licence                |
| Sharing                      | Run diagnostics and require confirmation that cross-account isolation has been tested   |
| Credentials                  | Report missing configuration without displaying or storing secret values                |
| Publication                  | Provide a readiness report; leave publication to an authorised subscriber administrator |

The wizard should support two completion states:

- **Core ready**: the internal PartnerSync application is configured and usable.
- **Portal ready**: core setup, Experience Cloud configuration, external security, and portal validation are complete.

## AppExchange listing language

Recommended prerequisite statement:

> PartnerSync's internal CRM capabilities require a supported Salesforce edition and appropriate Salesforce user licences. The optional partner portal requires Salesforce Experience Cloud, a configured Digital Experiences domain, and suitable external-user licences. Salesforce licences and Experience Cloud entitlements are not included with the PartnerSync subscription unless expressly stated in your order agreement.

Recommended installation statement:

> AppExchange installation provides the PartnerSync managed application. Portal customers complete a guided post-install process to create and configure a customer-owned Experience Cloud site from the PartnerSync template. Domain selection, branding, identity, sharing, credentials, external-user licensing, testing, and site publication remain subscriber-controlled steps.

Avoid marketing the product as a one-click published portal. A more accurate description is **a one-click core application install with a guided portal launch**.

## Upgrade behaviour

Core application upgrades are delivered as descendant managed 2GP versions. Before promoting an upgrade, PartnerSync must test:

1. clean installation of the new `04t...` version;
2. upgrade from every supported released ancestor;
3. preservation of subscriber data and permitted subscriber customisations;
4. compatibility of packaged LWCs with the supported Experience template versions;
5. permission and sharing changes; and
6. any manual portal-template migration steps.

An upgrade to the managed package does not automatically republish a subscriber's Experience Cloud site. When a release requires page or template changes, release notes must identify whether administrators need to apply a new page, update component properties, or republish their site.

## Responsibilities

| Responsibility                                                  | PartnerSync publisher         | Subscriber or implementation partner |
| --------------------------------------------------------------- | ----------------------------- | ------------------------------------ |
| Maintain managed package and namespace                          | Yes                           | No                                   |
| Pass package validation and AppExchange security review         | Yes                           | No                                   |
| Document supported Salesforce editions and licences             | Yes                           | Confirm purchase and availability    |
| Provide supported Experience template and setup guidance        | Yes                           | Install and configure                |
| Select Digital Experiences domain                               | No                            | Yes                                  |
| Purchase and assign Salesforce/Experience licences              | No                            | Yes                                  |
| Configure customer identity, branding, sharing, and credentials | Provide controls and guidance | Yes                                  |
| Validate package-isolated Apex                                  | Yes                           | Review release evidence              |
| Validate customer-specific portal and integrations              | Provide test guidance         | Yes                                  |
| Publish or unpublish the production site                        | No                            | Yes                                  |

## Release readiness checklist

Before describing PartnerSync as AppExchange-ready, confirm that:

- the managed 2GP release candidate was created with package code coverage and is promotable;
- clean install and ancestor upgrade tests pass;
- the AppExchange security review scope includes every distributed component;
- a supported Experience Builder template or Lightning Bolt distribution artifact exists;
- template dependencies resolve against the released PartnerSync package;
- the setup wizard distinguishes core readiness from portal readiness;
- external licence compatibility has been tested for every supported persona;
- cross-partner record isolation has been tested;
- secrets and environment-specific values are absent from all artifacts;
- installation, configuration, upgrade, and uninstall documentation is published; and
- the listing clearly states that Experience Cloud licences are not included.

## Repository mapping

| Repository location                                 | Intended use                                                                                                     |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `force-app`                                         | Source for the managed PartnerSync 2GP package                                                                   |
| `org-config`                                        | Development examples and subscriber configuration requiring review; not a wholesale customer deployment artifact |
| `docs/2gp-package-version-and-apex-test-runbook.md` | Package creation, installation, and Apex-test release process                                                    |
| `docs/post-install-sharing-setup.md`                | Subscriber security and sharing configuration                                                                    |
| `docs/experience-cloud-page-architecture.md`        | Experience Builder page and component architecture                                                               |

The long-term packaging goal is to convert reusable portal assets from `org-config` into a supported Experience Builder template or Lightning Bolt Solution, while retaining customer-specific security, identity, credentials, and publication settings as guided subscriber configuration.
