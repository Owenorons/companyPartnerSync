# AI request quota

`AIInsightController.enqueueInsight`, `AIInsightController.generateInsight`, and
`AIInsightGeneratorService.generate` now return an `AsyncApexJob` ID. Generation
is asynchronous; callers must use the existing insight review query after the
job completes instead of expecting an immediate insight DTO. There are no LWC
callers of the former synchronous endpoint in this repository.

Every valid request reserves a slot in `AI_Usage_Day__c` before its job is
enqueued. Existing daily counters are locked with `FOR UPDATE`; a unique UTC
day key prevents competing initial requests from creating separate counters.
The reservation and enqueue commit together. Provider work runs in the next
transaction, with no quota DML before the callout. A first-request collision
fails without a callout and can be retried.

The active `Tenant_Config__mdt.AI_Daily_Request_Limit` record's `Value__c` sets
the maximum daily reservations. Zero blocks all requests. Missing, inactive,
negative, or nonnumeric settings retain the previous unlimited behavior.
Reservations are counted even when unlimited, so enabling a limit later in the
same day includes those requests. On the first reservation of a day, existing
insights from that UTC day seed the counter to account for pre-upgrade usage.

**Upgrade note:** prior to this reservation system, a `Value__c` of `"0"` was
treated as unlimited (only positive values were enforced). Any org that has
already set `Value__c` to `"0"` will see AI generation fully blocked after
upgrading to this version, with no other change required to trigger it.
Confirm the configured value before upgrading a subscriber org.

Failed or aborted jobs retain their slot: provider work may already have been
billed even if Salesforce could not persist its result. Deleting an insight
does not restore quota. A job that starts on a later UTC day expires without
calling the provider; submit a new request to reserve capacity for that day.

The counter has private sharing and no permission-set grants. The
permission-gated reservation service maintains it in system mode so all users
share one tenant-wide count. Deploy the object and Apex changes together.

Regression coverage: `AIUsageServiceTest`, `AIInsightGovernanceServiceTest`,
`AIInsightGeneratorServiceTest`, and `ControllerErrorContractTest`. Real
simultaneous transactions require an org-level concurrency test; Apex unit tests
cover pending-job accounting and the unique-key invariant independently.
