#!/usr/bin/env python3
"""
Architecture static-check script (Sprint 45 Phase 5,
architecture-design-and-enhancement.md §45.61 "custom architectural static
checks"). Scans Apex source for a small set of anti-patterns this codebase
has deliberately avoided since Sprint 34, so a future regression is caught
automatically rather than only by manual review:

  1. EventBus.publish() called outside the two canonical durable-outbox
     publisher classes.
  2. A raw HTTP callout (new Http()/new HttpRequest()) outside the four
     established adapter classes (the two AI providers, the DocuSign
     adapter, the webhook dispatch adapter).
  3. Direct assignment to a small set of Deal-aggregate lifecycle fields
     (Conflict_Status__c, Protection_Status__c) from a file outside the
     established domain/command/approval folders - reported for review,
     not auto-failed, since a legitimate Database.update(..., Id = ...)
     partial-field update on an existing record is a normal pattern
     anywhere in this codebase and this heuristic cannot always tell the
     two apart. Status__c is deliberately excluded from this check: it is
     a near-universal field name across dozens of unrelated objects in
     this schema, so a bare "Status__c =" grep produced ~150 findings that
     were almost entirely false positives on unrelated objects (AI
     requests, onboarding, MDF, renewals, etc.) - not a usable signal.
     Conflict_Status__c/Protection_Status__c are distinctive enough to
     the Deal aggregate to stay precise. See
     docs/sprint45-architecture-reconciliation.md for the full manual
     audit this script's checks are drawn from.

This is not a CI pipeline (this repo has none) - it is a local, re-runnable
release-gate script, matching every other verification step already run at
the end of each sprint (Apex balance/XML checks, prettier, eslint, jest).

Usage: python3 scripts/ci/architecture_lint.py
Exit code 0 when no findings are outside the allowlists below; 1 otherwise.
"""

import glob
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "force-app", "main", "default")
CLASSES_ROOT = os.path.join(ROOT, "classes")

EVENTBUS_PUBLISH_ALLOWED_FILES = {
    "PlatformEventPublisherService.cls",
    "events/EventPublicationService.cls",
}

RAW_CALLOUT_ALLOWED_FILES = {
    "ai/OpenAIProvider.cls",
    "ai/AzureOpenAIProvider.cls",
    "partner/DocuSignSignatureProvider.cls",
    "events/WebhookDispatchQueueable.cls",
}

LIFECYCLE_FIELD_ALLOWED_DIRS = {
    "deals",
    "approvals",
    "participants",
    "customersuccess",
    "portfolio",
    "revenue",
    "implementation",
    "events",
}

LIFECYCLE_FIELDS = ("Conflict_Status__c", "Protection_Status__c")


def relpath(path):
    return os.path.relpath(path, CLASSES_ROOT).replace(os.sep, "/")


def is_test_file(path):
    return path.endswith("Test.cls") or "/tests/" in path.lower()


def find_cls_files():
    return sorted(glob.glob(os.path.join(CLASSES_ROOT, "**", "*.cls"), recursive=True))


def check_eventbus_publish(files):
    findings = []
    for path in files:
        rel = relpath(path)
        if rel in EVENTBUS_PUBLISH_ALLOWED_FILES or is_test_file(rel):
            continue
        src = open(path, encoding="utf-8").read()
        for match in re.finditer(r"EventBus\.publish\s*\(", src):
            line_no = src.count("\n", 0, match.start()) + 1
            findings.append(f"{rel}:{line_no}  EventBus.publish outside the canonical publisher classes")
    return findings


def check_raw_callouts(files):
    findings = []
    for path in files:
        rel = relpath(path)
        if rel in RAW_CALLOUT_ALLOWED_FILES or is_test_file(rel):
            continue
        src = open(path, encoding="utf-8").read()
        for pattern in (r"new\s+Http\s*\(", r"new\s+HttpRequest\s*\("):
            for match in re.finditer(pattern, src):
                line_no = src.count("\n", 0, match.start()) + 1
                findings.append(f"{rel}:{line_no}  raw HTTP callout outside the established adapter classes")
    return findings


def check_lifecycle_field_writes(files):
    findings = []
    for path in files:
        rel = relpath(path)
        if is_test_file(rel):
            continue
        top_dir = rel.split("/")[0] if "/" in rel else ""
        if top_dir in LIFECYCLE_FIELD_ALLOWED_DIRS:
            continue
        src = open(path, encoding="utf-8").read()
        for field in LIFECYCLE_FIELDS:
            for match in re.finditer(re.escape(field) + r"\s*=(?!=)", src):
                line_no = src.count("\n", 0, match.start()) + 1
                findings.append(
                    f"{rel}:{line_no}  {field} assigned outside the domain/command layer (review: may be a legitimate Database.update(..., Id=...) partial update)"
                )
    return findings


def main():
    files = find_cls_files()
    all_findings = []
    all_findings += check_eventbus_publish(files)
    all_findings += check_raw_callouts(files)
    lifecycle_findings = check_lifecycle_field_writes(files)

    print(f"Scanned {len(files)} Apex classes.\n")
    print(f"EventBus.publish / raw-callout violations: {len(all_findings)}")
    for finding in all_findings:
        print(f"  {finding}")
    print(f"\nLifecycle-field writes outside the domain/command layer (review, not auto-fail): {len(lifecycle_findings)}")
    for finding in lifecycle_findings:
        print(f"  {finding}")

    if all_findings:
        print("\nFAIL: real architectural violations found.")
        return 1
    print("\nOK: no EventBus.publish / raw-callout violations found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
