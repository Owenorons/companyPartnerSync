/*
 * PartnerSync design tokens — single source of truth.
 *
 * Loaded once (via lightning/platformResourceLoader) by
 * c-partner-sync-theme-layout, the component that wraps every page on the
 * Experience Cloud site, and declared on :root so every ps* component's
 * shadow DOM inherits it without redeclaring anything itself.
 *
 * "The Registry" — Phase 2 visual direction. Every core object in this
 * product is something being registered (a deal, a lead assignment, an MDF
 * request, a partner tier), so the system leans into that literally: ledger
 * ink, ruled entries, a five-tone partner-tier palette, and a serif/mono/sans
 * type split instead of the Phase 1 SaaS-blue-gradient/rounded-card look.
 *
 * Where a real Experience Cloud Theme Panel / Branding Set hook exists
 * (https://developer.salesforce.com/docs/atlas.en-us.exp_cloud_lwr.meta/exp_cloud_lwr/brand_hooks_map.htm),
 * each token is `var(--dxp-*, <current value as fallback>)` so changing the
 * theme in Setup restyles the whole app with no code change. Tokens with no
 * Theme Panel equivalent (status colors, tier colors, radius, shadow, size
 * scale) stay as plain values — see the notes above each group.
 *
 * Do NOT redeclare any of these on an individual component's :host — a
 * component-level declaration always wins over this :root stylesheet in the
 * cascade, which silently defeats theming for that component.
 */

:root {
  /* Brand — the ledger-ink accent. Maps to the Theme Panel's Brand Color. */
  --ps-color-primary: var(--dxp-g-brand, #33406b);
  --ps-color-primary-dark: var(--dxp-g-brand-1, #232c4c);

  /* Accent — same ink family as brand; the Registry direction has one
     signature color, not a separate "AI accent" hue. Kept as its own token
     (rather than aliased) so a future surface can still diverge on purpose. */
  --ps-color-accent: #33406b;
  --ps-color-accent-dark: #232c4c;

  /* Status colors are semantic (good/warning/critical) and intentionally
     do NOT follow the brand color — they must stay recognizable no matter
     what theme is applied. */
  --ps-color-success: #2f6b46;
  --ps-color-success-bg: #e3efe6;

  --ps-color-warning: #a6711f;
  --ps-color-warning-bg: #f5ead2;

  --ps-color-danger: #a5322c;
  --ps-color-danger-bg: #f5dedb;

  /* Partner tier tones — used only for rank/tier UI (badges, leaderboard
     medallions, tier chips), never as general-purpose accent color. Matches
     Account.Partner_Tier__c's actual picklist values exactly: Silver, Gold,
     Platinum, Strategic — there is no Bronze or Elite value on this field. */
  --ps-color-tier-silver: #7d8896;
  --ps-color-tier-gold: #b3872f;
  --ps-color-tier-platinum: #5f6b7a;
  --ps-color-tier-strategic: #4a2f5c;

  /* Neutral / surface — maps to the Theme Panel's Background Color */
  --ps-color-bg: var(--dxp-g-root, #f2f3ee);
  --ps-color-card: var(--dxp-g-root-1, #fbfbf8);
  --ps-color-border: var(--dxp-g-neutral, #d8dad2);
  --ps-color-border-strong: #171b24;

  /* Text — maps to the Theme Panel's Text Color */
  --ps-color-text: var(--dxp-g-root-contrast, #171b24);
  --ps-color-text-muted: var(--dxp-g-root-contrast-2, #3a4150);

  /* Corner radius — sharp throughout. Registry panels read as ruled ledger
     pages, not soft SaaS cards; anything still referencing these tokens
     (buttons, small controls) gets a light chamfer, not a pill. True
     circles (medallions, seal rings) use 999px directly, not this scale. */
  --ps-radius-xs: 0.15rem;
  --ps-radius-sm: 0.2rem;
  --ps-radius-md: 0.2rem;
  --ps-radius-lg: 0.25rem;
  --ps-radius-xl: 0.25rem;

  /* Elevation — mostly gone. Ledger rules carry separation between
     elements now, not floating shadow. Kept nonzero only where a panel
     genuinely floats above content (drawer, modal). */
  --ps-shadow-sm: none;
  --ps-shadow-md: none;
  --ps-shadow-lg: 0 2px 6px rgba(23, 27, 36, 0.12);

  /* Typography — three roles. Display serif for titles and named entities
     (customers, partners, campaigns); mono for every number, code, and
     status label; system sans for body copy and form controls, since this
     is still a dashboard that gets scanned and operated, not read. */
  --ps-font-family: var(
    --dxp-g-root-font-family,
    var(
      --dxp-s-html-font-family,
      -apple-system,
      BlinkMacSystemFont,
      "Segoe UI",
      Roboto,
      sans-serif
    )
  );

  --ps-font-display: Georgia, "Iowan Old Style", "Palatino Linotype",
    "Book Antiqua", Palatino, ui-serif, serif;

  --ps-font-mono: ui-monospace, "SF Mono", "IBM Plex Mono", Menlo, Consolas,
    monospace;

  --ps-font-xs: 0.75rem;
  --ps-font-sm: 0.875rem;
  --ps-font-md: var(--dxp-s-html-font-size, 1rem);
  --ps-font-lg: 1.25rem;
  --ps-font-xl: 1.75rem;
  --ps-font-2xl: 2.25rem;
}
