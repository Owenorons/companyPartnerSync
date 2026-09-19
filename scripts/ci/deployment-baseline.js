const fs = require("node:fs");
const { execFileSync } = require("node:child_process");

const baselineRef = (environment) => `tags/salesforce-deployed/${environment}`;

async function getBaseline(github, repo, environment) {
  try {
    const { data } = await github.rest.git.getRef({
      ...repo,
      ref: baselineRef(environment)
    });
    return data.object.sha;
  } catch (error) {
    // Authentication, rate limits, and server errors must fail the build.
    if (error.status !== 404) throw error;
    return null;
  }
}

async function buildArtifacts({
  github,
  context,
  core,
  run = execFileSync,
  files = fs,
  fullDeploy = process.env.FULL_DEPLOY === "true"
}) {
  const environments = {
    "refs/heads/feature": ["staging", "full-sandbox"],
    "refs/heads/main": ["production"]
  }[context.ref];
  if (!environments) throw new Error(`Unsupported release ref: ${context.ref}`);

  files.mkdirSync(".deployment", { recursive: true });
  let anyChanges = false;
  for (const environment of environments) {
    const base = await getBaseline(github, context.repo, environment);
    const mode = fullDeploy || !base ? "full" : "delta";
    let hasChanges = true;
    if (mode === "delta") {
      // Fetch the exact successful commit, including after a history rewrite.
      // A missing object is an error, never a reason to guess another base.
      run("git", ["fetch", "--no-tags", "origin", base], { stdio: "inherit" });
      const output = `.delta/${environment}`;
      files.mkdirSync(output, { recursive: true });
      run(
        "sf",
        [
          "sgd",
          "source",
          "delta",
          "--from",
          base,
          "--to",
          context.sha,
          "--output-dir",
          output,
          "--source-dir",
          "force-app",
          "--generate-delta"
        ],
        { stdio: "inherit" }
      );
      hasChanges = [
        `${output}/package/package.xml`,
        `${output}/destructiveChanges/destructiveChanges.xml`
      ].some((path) => /<types>/.test(files.readFileSync(path, "utf8")));
    }
    files.writeFileSync(
      `.deployment/${environment}.env`,
      `DEPLOY_MODE=${mode}\nHAS_CHANGES=${hasChanges}\n`
    );
    core.info(
      `${environment}: ${mode} from ${base || "no baseline"} to ${context.sha}`
    );
    anyChanges ||= hasChanges;
  }
  core.setOutput("has_changes", String(anyChanges));
}

async function recordSuccess({ github, context, environment }) {
  const ref = baselineRef(environment);
  const base = await getBaseline(github, context.repo, environment);
  if (base) {
    await github.rest.git.updateRef({
      ...context.repo,
      ref,
      sha: context.sha,
      force: true
    });
  } else {
    await github.rest.git.createRef({
      ...context.repo,
      ref: `refs/${ref}`,
      sha: context.sha
    });
  }
}

module.exports = { buildArtifacts, recordSuccess };
