# Retrieving the PartnerSync Portal Experience Cloud site

Full command reference for pulling the `PartnerSync_Portal` site's metadata
out of an org and into source. Everything here goes into
`org-config/main/default/`, **never** `force-app` — see
[Placement rule](#placement-rule) below.

All commands assume `<alias>` is the org that actually has the current site
(e.g. `psync-package-test3`). Substitute your target org.

## 0. Find real names first — don't guess

Every naming mistake in this project's history came from guessing a
metadata full name instead of checking it. Before retrieving anything:

```bash
sf org list metadata --metadata-type Network --target-org psync-package-test
sf org list metadata --metadata-type CustomSite --target-org psync-package-test
sf org list metadata --metadata-type DigitalExperienceConfig --target-org psync-package-test
sf org list metadata --metadata-type DigitalExperienceBundle --target-org psync-package-test
sf org list metadata --metadata-type NavigationMenu --target-org psync-package-test
sf org list metadata --metadata-type NetworkBranding --target-org psync-package-test
```

Use the exact `Full Name` column value from the output as the `--metadata`
member below. `DigitalExperienceBundle` full names are shaped like
`site/PartnerSync_Portal1` (with a `site/` prefix) — the other types are not.

## 1. Network (site network settings)

```bash
sf project retrieve start \
  --metadata "Network:PartnerSync_Portal1" \
  --target-metadata-dir temp2 --unzip \
  --target-org psync-functional-fixes-v2
```

→ place at `org-config/main/default/networks/PartnerSync_Portal.network-meta.xml`.

## 2. CustomSite (legacy VF "picasso" shell)

The `sites` folder / `.site-meta.xml` suffix maps to metadata type
**`CustomSite`**, not `Site`.

```bash
sf project retrieve start \
  --metadata "CustomSite:PartnerSync_Portal1" \
  --target-metadata-dir /temp2/retrieve --unzip \
  --target-org psync-functional-fixes-v2
```

→ `org-config/main/default/sites/PartnerSync_Portal.site-meta.xml`.

## 3. DigitalExperienceConfig + DigitalExperienceBundle (retrieve together)

These two are interdependent — retrieving `DigitalExperienceConfig` alone
has previously failed with a circular-dependency-style deploy error, and
`DigitalExperienceBundle` needs the config to exist first on deploy. Retrieve
both in one manifest:

```bash
cat > /tmp/digx-manifest.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>PartnerSync_Portal1</members>
        <name>DigitalExperienceConfig</name>
    </types>
    <types>
        <members>site/PartnerSync_Portal1</members>
        <name>DigitalExperienceBundle</name>
    </types>
    <version>66.0</version>
</Package>
EOF

sf project retrieve start \
  --manifest temp2/digx-manifest.xml \
  --target-metadata-dir temp2 --unzip \
  --target-org psync-functional-fixes-v2
```

**Do not use `ExperienceBundle` for this type of site.** This site is an
enhanced LWR site (it has a `DigitalExperienceConfig`), and enhanced LWR
sites store page/screen content under `DigitalExperienceBundle`, not the
legacy `ExperienceBundle`. `ExperienceBundle:PartnerSync_Portal1` will fail
with `Entity of type 'ExperienceBundle' named 'PartnerSync_Portal1' cannot
be found` even though `sf org list metadata --metadata-type ExperienceBundle`
lists it — that listing is misleading for enhanced LWR sites. This is not a
transient error; it fails identically across API versions and source vs.
mdapi retrieve format. See `docs/experience-cloud-page-retrieve.md` for the
full story.

Retrieved layout:

- `digitalExperienceConfigs/PartnerSync_Portal1.digitalExperienceConfig-meta.xml`
- `digitalExperiences/site/PartnerSync_Portal1/sfdc_cms__view/...` (pages),
  `sfdc_cms__route/...`, `sfdc_cms__theme/...`, `sfdc_cms__themeLayout/...`,
  `sfdc_cms__brandingSet/...`, `sfdc_cms__styles/...`,
  `sfdc_cms__site/...`, `sfdc_cms__appPage/...`,
  `sfdc_cms__languageSettings/...`, `sfdc_cms__mobilePublisherConfig/...`,
  plus `PartnerSync_Portal1.digitalExperience-meta.xml`

## 4. NavigationMenu

A site can have several (default nav, guest nav, internal nav, etc.) —
retrieve all of them, not just the default one:

```bash
sf project retrieve start \
  --metadata "NavigationMenu:SFDC_Default_Navigation_PartnerSync_Portal" \
             "NavigationMenu:Guest" \
             "NavigationMenu:Internal" \
  --target-metadata-dir /tmp/retrieve --unzip \
  --target-org <alias>
```

(Check `sf org list metadata --metadata-type NavigationMenu` for the actual
current set — it changes as menus are added in Experience Builder.)
→ `org-config/main/default/navigationMenus/`.

## 5. NetworkBranding

```bash
sf project retrieve start \
  --metadata "NetworkBranding:cbPartnerSync_Portal" \
  --target-metadata-dir /tmp/retrieve --unzip \
  --target-org <alias>
```

→ `org-config/main/default/networkBranding/` (produces both a
`.networkBranding-meta.xml` and a `.networkBranding` file).

## 6. Profiles

The site's guest/member profiles and Admin (for `classAccesses` /
`fieldPermissions` needed by the site):

```bash
sf project retrieve start \
  --metadata "Profile:PartnerSync Portal Profile" \
             "Profile:PartnerSync Partner User" \
             "Profile:PartnerSync Partner Tester" \
             "Profile:Admin" \
  --target-metadata-dir /tmp/retrieve --unzip \
  --target-org <alias>
```

→ `org-config/main/default/profiles/`.

## 7. Everything in one shot

Once you know the real names (step 0), a single combined manifest retrieves
everything above together — useful for a full refresh:

```bash
cat > /tmp/full-site-manifest.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types><members>PartnerSync_Portal</members><name>Network</name></types>
    <types><members>PartnerSync_Portal</members><name>CustomSite</name></types>
    <types><members>PartnerSync_Portal1</members><name>DigitalExperienceConfig</name></types>
    <types><members>site/PartnerSync_Portal1</members><name>DigitalExperienceBundle</name></types>
    <types>
        <members>SFDC_Default_Navigation_PartnerSync_Portal</members>
        <members>Guest</members>
        <members>Internal</members>
        <name>NavigationMenu</name>
    </types>
    <types><members>cbPartnerSync_Portal</members><name>NetworkBranding</name></types>
    <types>
        <members>PartnerSync Portal Profile</members>
        <members>PartnerSync Partner User</members>
        <members>PartnerSync Partner Tester</members>
        <members>Admin</members>
        <name>Profile</name>
    </types>
    <version>66.0</version>
</Package>
EOF

sf project retrieve start \
  --manifest /tmp/full-site-manifest.xml \
  --target-metadata-dir /tmp/retrieve --unzip \
  --target-org <alias>
```

## Placement rule

`sfdx-project.json` registers only `force-app` as a package directory
(`"package": "PartnerSync"`), and per `org-config/README.md`,
**package-version creation always reads only `force-app`**. Every metadata
type above is subscriber/environment-specific and unsupported in a 2GP
package, so it must never live in `force-app`.

Plain `sf project retrieve start` with no explicit destination defaults to
the project's default package directory (`force-app`) — it does not know
`org-config` exists, since `org-config` isn't a registered package
directory. That's why every command above retrieves into a scratch
directory (`--target-metadata-dir /tmp/retrieve --unzip`) instead of letting
the CLI place it directly: copy the retrieved files into the matching
`org-config/main/default/<type>/` folder by hand afterward, and diff against
what's already there before overwriting — retrieved content is the source
of truth, but check whether files were renamed/removed on the org side
(`git status` after copying will show it) so stale local files get deleted,
not just overwritten.

## Not retrieved here

`SharingSet` (`org-config/main/default/sharingSets/`) is documented as a
manual post-install step in `docs/post-install-sharing-setup.md` and isn't
part of this refresh flow.
