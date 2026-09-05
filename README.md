# PartnerSync

PartnerSync is a namespaced Salesforce Partner Relationship Management application for Experience Cloud. It covers partner onboarding, governed access provisioning, deal registration, MDF, content, analytics, notifications, and operational oversight.

## Architecture

The application uses domain-oriented Apex services and selectors behind Lightning controllers, LWC experiences for partner and internal users, and Custom Metadata for policy and lifecycle configuration. Sensitive actions are separated into capability permission sets and composed into persona permission-set groups.

Source is split by release boundary:

- `force-app` is the managed 2GP package source.
- `org-config` contains subscriber-specific Experience Cloud workspaces, profiles, reports, credentials, sharing sets, and legacy site configuration. It deliberately is not registered under `packageDirectories`; deployment tooling targets it explicitly so it cannot leak into a managed package version.

Important design references:

- [Experience Cloud page architecture](docs/experience-cloud-page-architecture.md)
- [Partner onboarding lifecycle](docs/partner-onboarding-enhancement-v2.md)
- [Deal lifecycle management](docs/deal-process-enhancement-v2.md)
- [2GP package version and Apex test runbook](docs/2gp-package-version-and-apex-test-runbook.md)
- [AppExchange and Experience Cloud installation model](docs/appexchange-and-experience-cloud-installation.md)
- [Post-install sharing](docs/post-install-sharing-setup.md)
- [Seed data and UAT setup](scripts/apex/SEEDING.md)

## Prerequisites

- Node.js 20
- Salesforce CLI
- A Dev Hub with the `psync` namespace linked for managed 2GP builds
- An org with Communities, Sites, and ExperienceBundle metadata enabled

Install JavaScript dependencies with `npm ci`.

## Local validation

Run the complete local quality gate:

```sh
npm run validate
```

This validates the 2GP project contract, lints LWC JavaScript, checks formatting, and runs Jest. Apex compilation and tests require an authenticated Salesforce org:

```sh
PARTNER_SYNC_TARGET_ORG=psync-dev ./scripts/test.sh
```

## Scratch org

```sh
./scripts/org-create.sh
./scripts/deploy.sh
```

The defaults use the alias `psync-dev`. Override them with `PARTNER_SYNC_SCRATCH_ALIAS`, `PARTNER_SYNC_SCRATCH_DAYS`, and `PARTNER_SYNC_TARGET_ORG`.

After deployment, assign the appropriate permission-set group and follow the setup steps in the architecture and seeding documents. Named Credential principals and secrets must be configured in the target org; secrets are not stored in source control.

## Second-generation package versions

The `force-app` directory declares the managed package name and a `0.1.0.NEXT` development version. Configure the package in the Dev Hub, then provide either its package alias or `0Ho` ID:

```sh
PARTNER_SYNC_PACKAGE=0Ho... \
PARTNER_SYNC_DEV_HUB=my-dev-hub \
./scripts/package-version.sh
```

Do not fabricate or copy package IDs between unrelated Dev Hubs. Once a released version exists, add its ancestor to `sfdx-project.json` before creating the next release line and validate both clean installation and upgrade installation.

## Release flow

Pull requests run project validation, ESLint, formatting, Jest coverage, and Salesforce Code Analyzer. Pushes build an immutable Git-delta artifact. The `feature` branch promotes through staging and full sandbox; `main` validates and quick-deploys to production.

Direct org deployment and managed-package publication are separate release modes. A production package release should additionally create a beta version, install it into a clean org, run Apex and smoke tests, test upgrade from the current ancestor, and only then promote the package version.

The current validated beta is `PartnerSync@0.1.0-3`
(`04tQE00000if7aTYAQ`). It passed the package coverage check at 90%. It is
not released and must not be promoted until clean-install and upgrade testing
are complete.

Package-isolated Apex tests live in `force-app`. Subscriber integration tests that require profiles, Experience Cloud users, sharing configuration, or subscriber permission assignments live in `org-config/main/default/classes` and run after package installation and subscriber setup.

## Security model

- External access is granted through thin permission sets and persona groups.
- Governed actions require dedicated custom permissions.
- Partner record access relies on private sharing plus the documented sharing-set configuration.
- Apex exposed to LWC or Experience Cloud must enforce sharing, CRUD/FLS, and capability checks at its trust boundary.
- AI and signature-provider integrations must use Named Credentials and External Credentials.

Never commit authentication URLs, access tokens, client secrets, private keys, exported production data, or Microsoft Office lock files.
