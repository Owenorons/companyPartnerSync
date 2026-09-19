# Salesforce CI/CD setup

The repository uses a promotion-branch release model:

```text
feature/* or bugfix/*
        |
        | pull request
        v
feature branch
        |
        +--> automatic staging deployment
        |
        +--> staging tester sign-off
        |
        +--> approved full-sandbox deployment
        |
        +--> full-sandbox testing
        |
        | pull request
        v
protected main branch
        |
        +--> production validation and deployment
```

Developers create feature, enhancement, and bug-fix branches from `feature`.
They merge those branches back into `feature` through pull requests. Direct
pushes to `feature` and `main` should be blocked.

## Workflows

### `.github/workflows/ci.yml`

CI runs for pull requests targeting either `feature` or `main`. It performs:

- Dependency installation with `npm ci`.
- ESLint.
- Prettier validation.
- LWC Jest tests with coverage.

It is also reusable by the deployment workflow, ensuring no deployment begins
until the same CI checks pass.

### `.github/workflows/ci-cd.yml`

CI/CD runs when a reviewed change is merged into `feature` or `main`.

For `feature`:

1. Repeat the reusable CI quality gate.
2. Generate an incremental Salesforce artifact from the merge commit.
3. Deploy it automatically to staging with all local Apex tests.
4. Run a staging smoke test.
5. Wait at the protected `full-sandbox` environment.
6. A tester approves only after staging testing is complete.
7. Deploy the identical artifact to the full sandbox.
8. Run all local Apex tests and a full-sandbox smoke test.

Testing then continues in the full sandbox. GitHub does not merge `feature`
into `main` automatically. Once full-sandbox testing is signed off, create a
pull request from `feature` to `main`.

For `main`:

1. Repeat CI.
2. Generate the exact merged metadata artifact.
3. Wait at the protected `production` environment.
4. Validate the artifact in production with all local Apex tests.
5. Quick-deploy the successful Salesforce validation ID.
6. Run a production smoke test.

## GitHub environments

Create these GitHub environments:

1. `staging`
2. `full-sandbox`
3. `production`

Add an environment secret named `SFDX_AUTH_URL` to each environment. Each value
must contain the `sfdxAuthUrl` for that environment's Salesforce org:

```sh
sf org display --target-org <alias> --verbose --json
```

Configure environment protection as follows:

| Environment    |               Required reviewers | Deployment branch |
| -------------- | -------------------------------: | ----------------- |
| `staging`      |                               No | `feature`         |
| `full-sandbox` | Staging testers/release managers | `feature`         |
| `production`   |                 Release managers | `main`            |

For `full-sandbox` and `production`, enable **Prevent self-review** and disable
administrator bypass where the GitHub plan supports those controls.

## Branch protection

### `feature`

- Require pull requests.
- Require `Lint, format, and LWC tests`.
- Require at least one reviewer.
- Require branches to be up to date.
- Block force pushes and deletion.
- Restrict direct pushes.

Developers branch from `feature` using names such as:

- `feature/partner-dashboard`
- `enhancement/mdf-workflow`
- `bugfix/share-revocation`

### `main`

- Require pull requests.
- Allow pull requests only from `feature` by team policy or an additional
  GitHub ruleset/status check.
- Require `Lint, format, and LWC tests`.
- Require full-sandbox tester/release-manager approval.
- Require branches to be up to date.
- Require conversation resolution.
- Block force pushes and deletion.
- Restrict direct pushes to administrators or the release automation account.

The production workflow runs only after the protected pull request is merged
into `main`.

## Incremental and recovery deployments

Normal deployments use `sfdx-git-delta@6.44.4` and include changed, deleted, and
renamed metadata. Each environment's delta starts at its last successful
deployment, recorded in a lightweight Git tag:

- `salesforce-deployed/staging`
- `salesforce-deployed/full-sandbox`
- `salesforce-deployed/production`

These tags advance only after deployment and smoke tests succeed. Failed,
cancelled, or skipped releases leave the corresponding baseline unchanged, so
the next release includes their outstanding changes. Staging and full sandbox
can have different baselines; the artifact contains a separate delta for each,
targeting the same release SHA. For example, if staging deployed A but full
sandbox failed, release B uses A as staging's base and the earlier successful
commit as full sandbox's base. The artifact is retained for ten days. Its name
includes the run and attempt; downstream jobs use the producing job's output
so retrying only failed jobs still downloads the original artifact.

Deployment jobs have `contents: write` permission to maintain these tags through
the GitHub API. Repository tag rules must allow the workflow to create and update
`salesforce-deployed/*`. CI and artifact generation retain read-only access.
The branch-level workflow concurrency covers artifact creation through promotion,
preventing another release on that branch from changing the baselines midway.

An environment without a baseline receives a full deployment. When adopting this
workflow for an existing org, you can instead create its lightweight tag at the
verified last successfully deployed commit before the first run. Do not seed it
from the latest branch commit unless that exact revision is already deployed.
API errors and failures fetching an existing baseline stop the build rather than
substituting a guessed commit.

For recovery, manually run **Salesforce CI/CD** with `full_deploy` enabled while
on the relevant branch. This deploys the complete `force-app` directory through
that branch's normal environment path.

Full deployments do not remove metadata that is absent from the source tree.
For an existing org with outstanding deletions, seed a verified baseline and use
an incremental deployment, or handle those deletions in a reviewed recovery.

Flow deletion has additional Salesforce Metadata API limitations. Deactivate
and remove flows through an explicitly reviewed release rather than relying on
an ordinary destructive delta.
