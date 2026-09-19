const expectedVersionId = process.argv[2];

if (!/^04t[A-Za-z0-9]{12,15}$/.test(expectedVersionId || "")) {
  console.error("Expected package version must be an explicit 04t ID.");
  process.exit(1);
}

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  input += chunk;
});
process.stdin.on("end", () => {
  const response = JSON.parse(input);
  if (response.status !== 0 || !Array.isArray(response.result)) {
    console.error("Could not read installed package versions.");
    process.exit(1);
  }

  const installed = response.result.find(
    (entry) =>
      entry.SubscriberPackageVersionId === expectedVersionId ||
      entry.Id === expectedVersionId
  );
  if (!installed) {
    console.error(
      `Expected PartnerSync version ${expectedVersionId} is not installed.`
    );
    process.exit(1);
  }

  const namespace =
    installed.SubscriberPackageNamespace || installed.NamespacePrefix;
  const name = installed.SubscriberPackageName || installed.Name;
  if (namespace !== "psync" && name !== "PartnerSync") {
    console.error(
      `${expectedVersionId} is not the PartnerSync managed package.`
    );
    process.exit(1);
  }

  console.log(
    `Verified installed PartnerSync package version ${expectedVersionId}.`
  );
});
