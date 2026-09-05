# PartnerSync subscriber configuration

This Salesforce source directory contains metadata that is intentionally outside the managed 2GP package.

It includes Experience Cloud workspaces and sites, profiles, sharing sets, reports and dashboards, Named/External Credentials, navigation and branding assets, legacy Visualforce site pages, and subscriber integration tests. These components are subscriber-specific, environment-specific, unsupported in managed 2GP, or depend on configuration that must exist after package installation.

Install the PartnerSync `04t…` package version before deploying this directory. Review and replace environment-specific values—especially site administrators, URLs, profiles, credential principals, and secrets—before deployment. Secrets must never be committed.

The current validation beta is `PartnerSync@0.1.0-2`
(`04tQE00000if7QnYAI`). Do not treat that beta as a production release until
clean-install, upgrade, security, and acceptance gates pass.

The normal repository deployment script deploys only `force-app`. To deploy reviewed subscriber configuration into a prepared development or implementation org, set `PARTNER_SYNC_DEPLOY_ORG_CONFIG=true`. Package-version creation always reads only `force-app`.

Subscriber integration tests that exercise guest users, external partner profiles, private-sharing behavior, or subscriber permission assignment belong under `org-config/main/default/classes`. Deploy and run them only after installing the managed package and completing the required subscriber setup. Package-isolated unit tests remain in `force-app` and provide the package-version coverage gate.
