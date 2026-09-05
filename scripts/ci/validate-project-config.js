const fs = require("node:fs");
const path = require("node:path");

const projectPath = path.resolve("sfdx-project.json");
const project = JSON.parse(fs.readFileSync(projectPath, "utf8"));
const errors = [];

// Customer-owned and environment-specific metadata must never leak into the
// managed core package. These assets are validated separately after install.
const subscriberOwnedMetadata = [
  "audience",
  "audiences",
  "dashboards",
  "digitalExperienceConfigs",
  "digitalExperiences",
  "externalCredentials",
  "namedCredentials",
  "navigationMenus",
  "networkBranding",
  "networks",
  "profiles",
  "reports",
  "sharingSets",
  "sites"
];

if (!project.namespace) errors.push("namespace is required for managed 2GP");
if (!project.sourceApiVersion) errors.push("sourceApiVersion is required");

const packageDirectories = project.packageDirectories || [];
const defaultDirectories = packageDirectories.filter((entry) => entry.default);
if (defaultDirectories.length !== 1) {
  errors.push("exactly one package directory must be marked default");
}

for (const entry of packageDirectories) {
  if (!entry.path) errors.push("package directory is missing path");
  if (entry.path && !fs.existsSync(path.resolve(entry.path))) {
    errors.push(`package directory does not exist: ${entry.path}`);
  }

  if (entry.package) {
    for (const key of ["versionName", "versionNumber"]) {
      if (!entry[key]) errors.push(`packaged directory is missing ${key}`);
    }
    if (
      entry.versionNumber &&
      !/^\d+\.\d+\.\d+\.(NEXT|LATEST|\d+)$/.test(entry.versionNumber)
    ) {
      errors.push(`invalid 2GP versionNumber: ${entry.versionNumber}`);
    }

    if (!entry.definitionFile) {
      errors.push(
        `packaged directory is missing definitionFile: ${entry.path}`
      );
    } else if (!fs.existsSync(path.resolve(entry.definitionFile))) {
      errors.push(
        `package definition file does not exist: ${entry.definitionFile}`
      );
    }

    if (path.normalize(entry.path) === path.normalize("org-config")) {
      errors.push("org-config must not be declared as a package directory");
    }

    const metadataRoot = path.resolve(entry.path, "main", "default");
    for (const metadataType of subscriberOwnedMetadata) {
      const candidate = path.join(metadataRoot, metadataType);
      if (fs.existsSync(candidate) && fs.readdirSync(candidate).length > 0) {
        errors.push(
          `subscriber-owned metadata must remain outside the managed package: ${path.relative(process.cwd(), candidate)}`
        );
      }
    }
  }
}

if (
  packageDirectories.some((entry) =>
    path.normalize(entry.path).startsWith(`org-config${path.sep}`)
  )
) {
  errors.push(
    "paths below org-config must not be declared as package directories"
  );
}

if (
  project.packageAliases?.PartnerSync &&
  !/^0Ho[A-Za-z0-9]{12,15}$/.test(project.packageAliases.PartnerSync)
) {
  errors.push("PartnerSync package alias must reference a real 0Ho package ID");
}

if (errors.length) {
  console.error(
    `Invalid Salesforce project configuration:\n- ${errors.join("\n- ")}`
  );
  process.exit(1);
}

const packagedDirectories = packageDirectories.filter((entry) => entry.package);
console.log(
  `Validated ${packagedDirectories.length} packaged ${packagedDirectories.length === 1 ? "directory" : "directories"} for namespace ${project.namespace}.`
);
