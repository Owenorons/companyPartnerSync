# PartnerSync 2GP Package Version and Apex Test Runbook

This runbook creates a real managed second-generation package (2GP) version, installs it into a clean Salesforce org, and runs the packaged Apex tests. It is written for the PartnerSync package in this repository and the Salesforce CLI commands available in version `2.143.6`.

Creating package versions, installing packages, and promoting versions changes Salesforce state. Run each command against the named org shown in the examples; do not rely on an unknown default org.

## Identifier reference

Salesforce packaging uses several identifiers that are not interchangeable:

| Identifier | Meaning                             | Used by                                                                   |
| ---------- | ----------------------------------- | ------------------------------------------------------------------------- |
| `0Ho…`     | Package ID                          | `sf package version create --package`                                     |
| `04t…`     | Subscriber Package Version ID       | `sf package install --package` and `sf package version promote --package` |
| `08c…`     | Package version creation request ID | `sf package version create report --package-create-request-id`            |

Use aliases locally where convenient, but retain the IDs in CI output and release records.

### Latest locally recorded beta — built 12 September 2026

| Item                          | Value                                               |
| ----------------------------- | --------------------------------------------------- |
| Dev Hub alias                 | `evosphereSolutions`                                |
| Package ID                    | `0HoQE0000000F8j0AE`                                |
| Version                       | `0.1.0.7`                                           |
| Package alias                 | `PartnerSync@0.1.0-7`                               |
| Subscriber Package Version ID | `04tQE00000ifZ25YAE`                                |
| Stored package coverage       | Not yet confirmed — run `sf package version report` |
| Coverage check                | Not yet confirmed — run `sf package version report` |
| Validation skipped            | No                                                  |
| Released                      | No (beta)                                           |
| Ancestor                      | None                                                |

Superseded the previous `0.1.0-6` (`04tQE00000ifSi9YAE`) build. Built to include
schema/Apex that existed in `force-app` but wasn't in `-6`'s snapshot
(`Account.Assigned_Channel_Manager__c`, `AIConnectionTestService`, and possibly
others — confirm by redeploying `org-config` against an org with this version
installed and checking whether those errors are gone).

These values were checked with `sf package version report` against the Dev Hub.
They establish package creation and coverage, not clean-install, upgrade, or
AppExchange security-review acceptance. No install acceptance is recorded here.
A package version is a snapshot; later working-tree changes require another build.

For the install and post-install examples below, set one candidate ID in your
terminal and keep using that same value. Replace it after a newer successful build:

```sh
export PARTNER_SYNC_CANDIDATE=04tQE00000ifZ25YAE
```

## 1. Confirm the prerequisites

You need:

1. A Salesforce production org with Dev Hub enabled.
2. Second-Generation Managed Packaging enabled in that Dev Hub.
3. The `psync` namespace registered and linked to the Dev Hub.
4. A Dev Hub user authorized to create packages and package versions.
5. A package test org, normally a fresh scratch org.
6. Salesforce CLI and the repository's Node.js dependencies.

From the repository root, verify the local toolchain and project contract:

```sh
sf --version
npm ci
npm run validate:project
```

The project declaration is in [`sfdx-project.json`](../sfdx-project.json). Namespace registration and linking are durable packaging decisions; confirm `psync` belongs to the intended product before creating the managed package.

## 2. Authenticate the Dev Hub

The existing package belongs to the Dev Hub authenticated as `evosphereSolutions`.
If that alias is already authenticated, skip login and verify it below. Otherwise,
log in to that same Dev Hub account:

```sh
sf org login web \
  --alias evosphereSolutions \
  --set-default-dev-hub
```

Verify the authenticated identity:

```sh
sf org display --target-org evosphereSolutions
sf config get target-dev-hub
```

CI should use a non-interactive authentication method and a protected secret. Never commit an SFDX authentication URL, private key, access token, or client secret.

## 3. Find the existing package ID

List packages owned by the Dev Hub:

```sh
sf package list --target-dev-hub evosphereSolutions
```

Locate the managed package named `PartnerSync` and record its `0Ho…` ID.

Do not create another package merely because a local alias is missing. A package name must be unique within its namespace, and creating an unnecessary package fragments version history.

## 4. Create the package only when it does not exist

**Skip this step for this repository: PartnerSync already exists as
`0HoQE0000000F8j0AE`.** The command below is only for an intentionally separate
new package setup.

```sh
sf package create \
  --name PartnerSync \
  --package-type Managed \
  --path force-app \
  --description "PartnerSync Partner Relationship Management" \
  --target-dev-hub evosphereSolutions
```

Record the returned `0Ho…` package ID. Then add a local alias to `sfdx-project.json` using the actual value:

```json
{
  "packageAliases": {
    "PartnerSync": "0Ho000000000000AAA"
  }
}
```

Replace the example value; never commit a fabricated ID. Package aliases identify Salesforce metadata and are not credentials, so the real package alias can normally be committed when every developer and CI environment uses the same Dev Hub lineage.

Verify that the alias resolves:

```sh
sf package list --target-dev-hub evosphereSolutions
npm run validate:project
```

## 5. Review the version definition

Before creating a version, inspect `sfdx-project.json`. The PartnerSync package directory should identify:

- `package`: `PartnerSync`
- `versionName`: the intended release name
- `versionNumber`: currently `0.1.0.NEXT`; `NEXT` selects the next build number
- `ancestorVersion` or `ancestorId`: required for subsequent managed release lines
- dependencies, when PartnerSync depends on another package

For the first version, no ancestor exists. After the first version is released, establish the correct ancestor before building an upgrade version. Do not use `--skip-ancestor-check` as a routine workaround.

Run the local quality gate before consuming package-version capacity:

```sh
npm run validate
node --test scripts/ci/deployment-baseline.test.js
```

`npm run validate` runs local project, lint, formatting, and LWC checks. The
Node CI tests run separately from Jest. Neither command executes Apex; package
creation with `--code-coverage` provides the packaged Apex test gate.

## 6. Create a validated beta package version

The repository helper creates a validated version and requests packaged Apex coverage:

```sh
PARTNER_SYNC_PACKAGE=PartnerSync \
PARTNER_SYNC_DEV_HUB=evosphereSolutions \
PARTNER_SYNC_PACKAGE_WAIT_MINUTES=90 \
./scripts/package-version.sh
```

During package-boundary development, a metadata-validated beta can be created without calculating stored package coverage:

```sh
PARTNER_SYNC_PACKAGE=PartnerSync \
PARTNER_SYNC_DEV_HUB=evosphereSolutions \
PARTNER_SYNC_CODE_COVERAGE=false \
./scripts/package-version.sh
```

This version can be installed in a test org, but it is not a release candidate and cannot be promoted until a new package version is created successfully with `PARTNER_SYNC_CODE_COVERAGE=true`.

If the alias has not yet been committed, use the real `0Ho…` ID as `PARTNER_SYNC_PACKAGE`.

For metadata that depends on scratch-org features or settings, run the equivalent explicit command with the definition file:

```sh
sf package version create \
  --package PartnerSync \
  --definition-file config/package-test-scratch-def.json \
  --installation-key-bypass \
  --code-coverage \
  --wait 90 \
  --target-dev-hub evosphereSolutions \
  --verbose
```

Do not use `--skip-validation` for a release candidate. A skipped-validation version cannot be promoted, and it omits package validation and coverage checks.

The result contains:

- an `08c…` creation request ID; and
- after successful completion, an `04t…` Subscriber Package Version ID.

If the command times out while Salesforce continues processing, query the request rather than starting a duplicate build:

```sh
sf package version create report \
  --package-create-request-id 08c... \
  --target-dev-hub evosphereSolutions
```

You can also inspect recent requests and versions:

```sh
sf package version create list --target-dev-hub evosphereSolutions
sf package version list --packages PartnerSync --target-dev-hub evosphereSolutions
```

Save the successful `04t…` ID as the immutable release-candidate identifier.

## 7. Review package coverage and errors

The `--code-coverage` option runs the Apex tests included in the package and stores package-version coverage. A promotable managed package version must satisfy Salesforce's package coverage requirement.

Inspect the version details:

```sh
sf package version report \
  --package "${PARTNER_SYNC_CANDIDATE:?Set the candidate 04t ID first}" \
  --target-dev-hub evosphereSolutions
```

If creation fails, diagnose the original `08c…` request. Fix source, metadata dependencies, test failures, or coverage locally and create a new build number. A failed or obsolete package version is not repaired in place.

## 8. Create a clean package-test org

Create a fresh scratch org so the install test cannot accidentally depend on unpackaged metadata:

```sh
sf org create scratch \
  --definition-file config/package-test-scratch-def.json \
  --alias psync-package-test \
  --no-namespace \
  --no-ancestors \
  --duration-days 30 \
  --target-dev-hub evosphereSolutions \
  --wait 30
```

Use `--no-namespace` to model a subscriber org rather than a development org
inside `psync`; `--no-ancestors` prevents automatic ancestor installation. See
the [Salesforce scratch-org command reference](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_org_create_scratch.html).

Confirm the target before installing:

```sh
sf org display --target-org psync-package-test
```

Do not deploy `force-app` into this org first. The purpose of this org is to prove that the package alone supplies its declared metadata.

## 9. Install the beta version

A beta package version cannot be installed as an upgrade over a different beta
version in the same org — Salesforce only supports upgrade installs over a
`Released` ancestor (see step 13). Until a version is released, installing a
newer beta requires a **fresh scratch org per beta build**; reinstalling into
an org that already has an older beta installed will fail. Create a new
scratch org (step 8) for each new candidate rather than trying to reuse one.

Install using the `04t…` Subscriber Package Version ID, not the `0Ho…` package ID:

```sh
sf package install \
  --package "${PARTNER_SYNC_CANDIDATE:?Set the candidate 04t ID first}" \
  --target-org psync-package-test \
  --security-type AdminsOnly \
  --wait 30 \
  --publish-wait 20 \
  --no-prompt
```

If installation continues after the command's wait period, use the install request ID returned by Salesforce:

```sh
sf package install report \
  --request-id 0Hf... \
  --target-org psync-package-test
```

An installation failure in an otherwise clean compatible org is a release blocker. Capture the install request and failure details in the release record.

## 10. Apply subscriber-side setup

Package installation does not provide secrets or perform all subscriber-specific configuration. Complete only the setup required for verification:

1. Configure Named Credential and External Credential principals without storing secrets in Git.
2. Assign the relevant PartnerSync permission-set group to the test user.
3. Apply the documented sharing setup in [`post-install-sharing-setup.md`](post-install-sharing-setup.md).
4. Activate or configure Experience Cloud only when the test scenario requires it.
5. Run the appropriate seed scripts described in [`scripts/apex/SEEDING.md`](../scripts/apex/SEEDING.md).

Keep installability testing separate from UAT data setup. First prove that installation succeeds with no unpackaged application metadata.

After reviewing the target org and the choices above, the guarded repository
helper can perform the repeatable portion of setup:

```sh
PARTNER_SYNC_TARGET_ORG=psync-package-test \
PARTNER_SYNC_EXPECTED_PACKAGE_VERSION="${PARTNER_SYNC_CANDIDATE:?Set the candidate 04t ID first}" \
PARTNER_SYNC_DEPLOY_ORG_CONFIG=false \
PARTNER_SYNC_RUN_POST_INSTALL_TESTS=true \
./scripts/post-install.sh
```

The target alias is mandatory. `org-config` is skipped unless explicitly
enabled because it contains customer- and environment-specific metadata. The
helper assigns the running internal user the packaged administrator group,
schedules idempotent operational jobs, runs the namespace-safe smoke check,
and optionally runs `RunAllTestsInOrg`.

The helper does not configure credentials or secrets, select Experience Cloud
licences or domains, publish a site, create external users, or approve Sharing
Set mappings. Those remain explicit subscriber-administrator decisions.

## 11. Run packaged Apex tests

`RunLocalTests` does **not** run tests originating from an installed managed package. In the clean package-test org, use `RunAllTestsInOrg` to include PartnerSync's managed tests:

```sh
sf apex run test \
  --target-org psync-package-test \
  --test-level RunAllTestsInOrg \
  --code-coverage \
  --detailed-coverage \
  --result-format human \
  --wait 90
```

For CI, retain machine-readable results:

```sh
mkdir -p reports/apex
sf apex run test \
  --target-org psync-package-test \
  --test-level RunAllTestsInOrg \
  --code-coverage \
  --result-format junit \
  --output-dir reports/apex \
  --wait 90
```

If a shared test org contains unrelated tests, explicitly run PartnerSync test classes using their installed namespace, for example:

```sh
sf apex run test \
  --target-org psync-package-test \
  --tests psync.Partner360ServiceTest \
  --tests psync.PartnerOnboardingLifecycleServiceTest \
  --code-coverage \
  --result-format human \
  --wait 60
```

The package-version creation coverage is the authoritative coverage result for promotion. The installed-org test run additionally verifies runtime behavior in subscriber context.

## 12. Run post-install smoke verification

Execute the repository smoke script after installation and minimum setup:

```sh
sf apex run \
  --file scripts/apex/post-deployment-smoke.apex \
  --target-org psync-package-test
```

The smoke script discovers whether packaged object API names use the `psync__`
prefix, so the same source works in a subscriber org and the namespace
development org.

Then exercise the critical flows appropriate to the release, including permission boundaries, partner isolation, onboarding transitions, asynchronous jobs, Experience Cloud pages, and integration failure handling.

## 13. Test an upgrade

The recorded beta has no released ancestor. For the first release, record this
gate as not applicable after confirming there is no released version to upgrade
from. Once a version is released, use it as the baseline below; do not treat a
prior beta as a supported released upgrade baseline.

Clean installation and upgrade installation are different tests. Create a second scratch org and:

1. Install the currently released ancestor using its released `04t…` ID.
2. Seed representative records through supported application behavior.
3. Install the new beta `04t…` ID into the same org.
4. Re-run all Apex tests and smoke checks.
5. Verify data migration, scheduled jobs, permissions, Custom Metadata, Experience Cloud configuration, and removed/deprecated components.

Managed package upgrade example:

```sh
sf package install \
  --package 04t_CURRENT_RELEASE... \
  --target-org psync-package-upgrade \
  --security-type AdminsOnly \
  --wait 30 \
  --no-prompt

sf package install \
  --package 04t_NEW_BETA... \
  --target-org psync-package-upgrade \
  --security-type AdminsOnly \
  --wait 30 \
  --no-prompt
```

Do not use unlocked-package `--upgrade-type` flags for this managed package.

## 14. Promote only the approved version

Promotion changes a beta package version to released and is not a routine test action. Promote only after clean install, upgrade, Apex, smoke, security, and release-approval gates pass.

```sh
sf package version promote \
  --package "${PARTNER_SYNC_CANDIDATE:?Set the candidate 04t ID first}" \
  --target-dev-hub evosphereSolutions \
  --no-prompt
```

Verify the released state:

```sh
sf package version report \
  --package "${PARTNER_SYNC_CANDIDATE:?Set the candidate 04t ID first}" \
  --target-dev-hub evosphereSolutions
```

Record the Git commit, `0Ho…` package ID, `04t…` released version ID, semantic version, ancestor, creation request, coverage, clean-install result, upgrade result, and approver in the release evidence.

## Recent AI regression checks

For builds containing the AI quota and review changes, include
`AIUsageServiceTest`, `AIInsightGeneratorServiceTest`,
`AIInsightGovernanceServiceTest`, and `AIProviderRouterTest` in focused diagnosis.
The full package creation test gate must still pass.

- Queue requests deserialize scalar context through untyped JSON; typed DTO
  deserialization of `Map<String, Object>` previously failed during package tests.
- The success test uses an in-memory active provider configuration. Packaged
  OpenAI configuration remains inactive until a subscriber administrator configures
  and enables it; an HTTP mock alone does not enable the provider router.
- Review tests verify persisted status and recommendation, not just returned DTOs.
- Generation now returns an asynchronous job ID. See [AI request quota](ai-request-quota.md)
  for reservation, UTC-day, and failure behavior.

## Troubleshooting checklist

### Package or alias is not found

- Run `sf package list --target-dev-hub evosphereSolutions`.
- Confirm the authenticated user belongs to the correct Dev Hub.
- Confirm the actual `0Ho…` ID is mapped under `packageAliases`.

### Namespace errors

- Confirm `sfdx-project.json` declares `psync`.
- Confirm the namespace is registered and linked to this Dev Hub.
- Do not create a second managed package to work around a namespace mismatch.

### Package creation times out

- Query the returned `08c…` request with `sf package version create report`.
- Do not submit duplicate builds until the prior request has reached a terminal state.

### Package creation fails on features or settings

- Pass `--definition-file config/package-test-scratch-def.json` for core package validation. Use `config/project-scratch-def.json` only for portal-enabled development and integration testing.
- Add only real package prerequisites to the scratch definition.
- Verify that subscriber orgs can satisfy those prerequisites.

### Apex tests appear to be skipped after installation

- Replace `RunLocalTests` with `RunAllTestsInOrg`.
- Alternatively, specify installed tests with the `psync.` namespace.

### Package installs but the application is not operational

- Complete permission, sharing, Experience Cloud, Named Credential, scheduling, and seed-data setup.
- Keep missing subscriber setup distinct from package metadata defects.

## Completion criteria

A PartnerSync package candidate is ready for release review only when:

- a validated package version was created with stored Apex coverage;
- the version installs into a clean compatible org;
- packaged Apex tests pass in subscriber context;
- the post-install smoke test passes;
- partner access and sharing boundaries are verified;
- upgrade from the current released ancestor passes, or is recorded as not applicable for the first release;
- no secrets or org-specific credentials are embedded in the package; and
- the exact `04t…` candidate and Git commit have been recorded.
