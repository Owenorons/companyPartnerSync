for (CronTrigger job : [
  SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'PartnerSync Operational Alerts Hourly'
]) {
  System.abortJob(job.Id);
}
