String jobName = 'PartnerSync Operational Alerts Hourly';
List<CronTrigger> existingJobs = [
  SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName AND State IN ('WAITING', 'ACQUIRED', 'PAUSED')
];
if (existingJobs.isEmpty()) {
  System.schedule(jobName, '0 0 * * * ?', new PartnerOperationalAlertService());
}
