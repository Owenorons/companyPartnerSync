#!/usr/bin/env node

const fs = require("node:fs");

const reportPath = process.argv[2];
const baselinePath = process.argv[3] || "config/code-analyzer-baseline.json";

if (!reportPath) {
  throw new Error(
    "Usage: check-code-analyzer-baseline.js <report.sarif> [baseline.json]"
  );
}

const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
const baseline = JSON.parse(fs.readFileSync(baselinePath, "utf8"));
const counts = {};

for (const run of report.runs || []) {
  const rules = run.tool?.driver?.rules || [];

  for (const result of run.results || []) {
    const severity = rules[result.ruleIndex]?.properties?.severity;
    if (severity !== undefined) {
      counts[severity] = (counts[severity] || 0) + 1;
    }
  }
}

const regressions = [];
for (const [severity, maximum] of Object.entries(
  baseline.maximumBySeverity || {}
)) {
  const actual = counts[severity] || 0;
  console.log(`Severity ${severity}: ${actual} finding(s), maximum ${maximum}`);

  if (actual > maximum) {
    regressions.push(`severity ${severity}: ${actual} > ${maximum}`);
  }
}

if (regressions.length > 0) {
  throw new Error(
    `Code Analyzer regression detected: ${regressions.join(", ")}`
  );
}
