const assert = require("node:assert/strict");
const { test } = require("node:test");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { buildArtifacts, recordSuccess } = require("./deployment-baseline");

function fixture(baselines = {}, manifests = {}) {
  const writes = {};
  const commands = [];
  const outputs = {};
  const mutations = [];
  return {
    writes,
    commands,
    outputs,
    mutations,
    context: {
      repo: { owner: "test", repo: "test" },
      ref: "refs/heads/feature",
      sha: "release-b"
    },
    github: {
      rest: {
        git: {
          async getRef({ ref }) {
            const sha = baselines[ref.split("/").at(-1)];
            if (sha instanceof Error) throw sha;
            if (!sha)
              throw Object.assign(new Error("Not found"), { status: 404 });
            return { data: { object: { sha } } };
          },
          async updateRef(args) {
            mutations.push(args);
          },
          async createRef(args) {
            mutations.push(args);
          }
        }
      }
    },
    core: {
      info() {},
      setOutput(key, value) {
        outputs[key] = value;
      }
    },
    run(command, args) {
      commands.push([command, args]);
    },
    files: {
      mkdirSync() {},
      writeFileSync(file, content) {
        writes[file] = content;
      },
      readFileSync(file) {
        return manifests[file] || "<Package/>";
      }
    },
    fullDeploy: false
  };
}

test("first deployment uses full source, without guessing a Git base", async () => {
  const f = fixture();
  await buildArtifacts(f);
  assert.equal(f.commands.length, 0);
  assert.equal(f.outputs.has_changes, "true");
  assert.match(f.writes[".deployment/staging.env"], /DEPLOY_MODE=full/);
  assert.match(f.writes[".deployment/full-sandbox.env"], /DEPLOY_MODE=full/);
  assert.deepEqual(f.mutations, []);
});

test("failed release changes and deletions remain in the next environment delta", async () => {
  const directory = fs.mkdtempSync(
    path.join(os.tmpdir(), "deployment-baseline-")
  );
  const git = (...args) =>
    execFileSync("git", args, { cwd: directory, encoding: "utf8" }).trim();
  try {
    git("init", "--quiet");
    git("config", "user.email", "test@example.invalid");
    git("config", "user.name", "Test");
    fs.mkdirSync(path.join(directory, "force-app"));
    fs.writeFileSync(path.join(directory, "force-app/removed.cls"), "old");
    git("add", ".");
    git("commit", "--quiet", "-m", "Successful release");
    const success = git("rev-parse", "HEAD");
    fs.unlinkSync(path.join(directory, "force-app/removed.cls"));
    fs.writeFileSync(path.join(directory, "force-app/a.cls"), "release A");
    git("add", ".");
    git("commit", "--quiet", "-m", "A succeeds only in staging");
    const releaseA = git("rev-parse", "HEAD");
    fs.writeFileSync(path.join(directory, "force-app/b.cls"), "release B");
    git("add", ".");
    git("commit", "--quiet", "-m", "Next push");
    const f = fixture({ staging: releaseA, "full-sandbox": success });
    f.context.sha = git("rev-parse", "HEAD");
    const changes = {};
    f.run = (command, args) => {
      if (command !== "sf") return;
      const value = (flag) => args[args.indexOf(flag) + 1];
      changes[value("--output-dir")] = git(
        "diff",
        "--name-status",
        value("--from"),
        value("--to"),
        "--",
        "force-app"
      );
    };
    await buildArtifacts(f);
    assert.equal(changes[".delta/staging"], "A\tforce-app/b.cls");
    assert.match(changes[".delta/full-sandbox"], /A\tforce-app\/a.cls/);
    assert.match(changes[".delta/full-sandbox"], /A\tforce-app\/b.cls/);
    assert.match(changes[".delta/full-sandbox"], /D\tforce-app\/removed.cls/);
    assert.deepEqual(f.mutations, []);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("destructive-only changes still deploy", async () => {
  const f = fixture(
    { production: "last-success" },
    {
      ".delta/production/destructiveChanges/destructiveChanges.xml":
        "<Package><types></types></Package>"
    }
  );
  f.context.ref = "refs/heads/main";
  await buildArtifacts(f);
  assert.equal(f.outputs.has_changes, "true");
  assert.match(f.writes[".deployment/production.env"], /HAS_CHANGES=true/);
});

test("empty deltas skip deployment", async () => {
  const f = fixture({ staging: "success", "full-sandbox": "success" });
  await buildArtifacts(f);
  assert.equal(f.outputs.has_changes, "false");
});

test("explicit full deployment overrides existing baselines", async () => {
  const f = fixture({ staging: "success", "full-sandbox": "success" });
  f.fullDeploy = true;
  await buildArtifacts(f);
  assert.equal(f.commands.length, 0);
  assert.equal(f.outputs.has_changes, "true");
});

test("API failures fail closed instead of silently using a full deployment", async () => {
  const f = fixture({
    staging: Object.assign(new Error("Forbidden"), { status: 403 })
  });
  await assert.rejects(buildArtifacts(f), /Forbidden/);
  assert.equal(f.commands.length, 0);
});

test("unavailable baseline commits fail instead of using the previous push", async () => {
  const f = fixture({ staging: "missing-commit" });
  f.run = () => {
    throw new Error("Fetch failed");
  };
  await assert.rejects(buildArtifacts(f), /Fetch failed/);
  assert.deepEqual(f.mutations, []);
});

test("successful deployments create or advance only their environment tag", async () => {
  for (const baselines of [{}, { staging: "previous" }]) {
    const f = fixture(baselines);
    await recordSuccess({ ...f, environment: "staging" });
    assert.deepEqual(f.mutations, [
      {
        ...f.context.repo,
        ref: `${baselines.staging ? "" : "refs/"}tags/salesforce-deployed/staging`,
        sha: f.context.sha,
        ...(baselines.staging ? { force: true } : {})
      }
    ]);
  }
});
