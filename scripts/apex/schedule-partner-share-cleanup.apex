/*
 * PartnerSync post-install: schedule the expired-share cleanup batch.
 *
 * PartnerShareCleanupBatch revokes Partner_Record_Share__c grants whose
 * Expiry_Date__c has passed (see PartnerShareService.revokeAccess), but
 * nothing schedules it automatically after deployment — see
 * docs/post-install-sharing-setup.md.
 *
 * Run this once per org via Execute Anonymous (VS Code: right-click this
 * file > "Execute Anonymous Apex with Editor Contents", or
 * `sf apex run --file scripts/apex/schedule-partner-share-cleanup.apex
 * --target-org <alias>`).
 *
 * Safe to re-run: it checks for an existing job with the same name first
 * instead of erroring out on a duplicate CronTrigger.
 */

String jobName = 'PartnerSync Partner Share Cleanup';
String cronExpression = '0 0 2 * * ?'; // Daily at 2:00 AM org time.

List<CronTrigger> existingJobs = [
  SELECT Id
  FROM CronTrigger
  WHERE CronJobDetail.Name = :jobName
  LIMIT 1
];

if (!existingJobs.isEmpty()) {
  System.debug(
    '"' +
      jobName +
      '" is already scheduled (CronTrigger Id: ' +
      existingJobs[0].Id +
      '). Nothing to do.'
  );
} else {
  Id scheduledJobId = System.schedule(
    jobName,
    cronExpression,
    new psync.PartnerShareCleanupBatch()
  );

  System.debug(
    'Scheduled PartnerShareCleanupBatch to run daily at 2:00 AM. Job Id: ' +
      scheduledJobId
  );
}
