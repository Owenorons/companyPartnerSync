# Retrieving Experience Cloud page/screen content

`PartnerSync_Portal` is an **enhanced LWR site**, identified by having a
`DigitalExperienceConfig` (`org-config/main/default/digitalExperienceConfigs/`).
Enhanced LWR sites store their actual page/screen content — the LWC
placements built in Experience Builder — under the `DigitalExperienceBundle`
metadata type, **not** `ExperienceBundle`.

## The symptom

`NavigationMenu`, `NetworkBranding`, and `Network` never contain page
content — they're site chrome/config only (nav links, branding colors,
network settings). If you retrieve only those and go looking for your
pages, they won't be there no matter how carefully you look.

## The trap

The local folder structure (`digitalExperiences/site/<Name>/sfdc_cms__view/...`)
looks like it maps to the `ExperienceBundle` metadata type, and
`sf org list metadata --metadata-type ExperienceBundle` will even list your
site by name. Retrieving with that type anyway fails:

```
sf project retrieve start --metadata "ExperienceBundle:PartnerSync_Portal1" ...
# → Entity of type 'ExperienceBundle' named 'PartnerSync_Portal1' cannot be found
```

This happens consistently regardless of API version or source vs. mdapi
retrieve format — it is not a transient/indexing issue. The real cause: this
site is enhanced LWR, so the correct type is `DigitalExperienceBundle`.

## The fix

1. Confirm the real bundle name (it's usually `site/<DeveloperName>`, not
   just `<DeveloperName>`):
   ```bash
   sf org list metadata --metadata-type DigitalExperienceBundle --target-org <alias>
   ```
2. Retrieve using that exact full name:
   ```bash
   sf project retrieve start \
     --metadata "DigitalExperienceBundle:site/PartnerSync_Portal1" \
     --target-metadata-dir temp --unzip \
     --target-org psync-package-test3
   ```
   This produces the familiar `digitalExperiences/site/<Name>/sfdc_cms__*`
   folder structure (views, routes, theme, branding, styles, site config).

## Where retrieved files go

Everything Experience-Cloud-related — `digitalExperiences`, `networks`,
`navigationMenus`, `networkBranding`, `digitalExperienceConfigs`, `sites` —
belongs under **`org-config/main/default/`**, never `force-app`.
`force-app` is the packaged 2GP directory; per `org-config/README.md`,
package-version creation reads only `force-app`, and this metadata is
subscriber/environment-specific and unpackageable in 2GP. A plain
`sf project retrieve start --metadata ...` with no explicit target defaults
to the project's default package directory (`force-app`, per
`sfdx-project.json`), so retrieves for this metadata always need an
explicit destination — retrieve into a scratch dir first, then copy into the
matching `org-config/main/default/<type>/` folder by hand.
