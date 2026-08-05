/*
 * Run once per org after deployment. Safe to re-run because it checks for an
 * existing job before scheduling the hourly reconciliation.
 *
 * sf apex run --file scripts/apex/schedule-partner-provisioning-reconciliation.apex
 * --target-org <alias>
 */
String jobName = 'PartnerSync Provisioning Reconciliation';
List<CronTrigger> existingJobs = [
  SELECT Id
  FROM CronTrigger
  WHERE CronJobDetail.Name = :jobName
  LIMIT 1
];

if (existingJobs.isEmpty()) {
  Id scheduledJobId = System.schedule(
    jobName,
    '0 0 * * * ?',
    new psync.PartnerProvisioningReconciler()
  );
  System.debug('Scheduled provisioning reconciliation: ' + scheduledJobId);
} else {
  System.debug('Provisioning reconciliation is already scheduled.');
}
