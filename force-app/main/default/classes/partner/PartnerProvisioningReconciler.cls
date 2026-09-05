/*
 * Prevents an application from remaining Queued forever when Salesforce does
 * not execute the worker or its terminal-status job. Run hourly; only jobs
 * older than 24 hours are considered stale.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerProvisioningReconciler implements Schedulable {
  @TestVisible
  private static final Integer STALE_AFTER_HOURS = 24;

  public void execute(SchedulableContext context) {
    reconcileStaleProvisioning();
  }

  @TestVisible
  private static void reconcileStaleProvisioning() {
    List<Partner_Application__c> staleApplications = [
      SELECT Id, Provisioning_Job_Id__c, Provisioning_Started_On__c
      FROM Partner_Application__c
      WHERE
        Provisioning_Status__c = 'Queued'
        AND Provisioning_Started_On__c <= :System.now()
          .addHours(-STALE_AFTER_HOURS)
      LIMIT 200
      FOR UPDATE
    ];

    if (staleApplications.isEmpty()) {
      return;
    }

    Set<String> jobIds = new Set<String>();
    for (Partner_Application__c application : staleApplications) {
      if (!String.isBlank(application.Provisioning_Job_Id__c)) {
        jobIds.add(application.Provisioning_Job_Id__c);
      }
    }

    Map<String, AsyncApexJob> jobsById = new Map<String, AsyncApexJob>();
    if (!jobIds.isEmpty()) {
      for (AsyncApexJob job : [
        SELECT Id, Status, ExtendedStatus
        FROM AsyncApexJob
        WHERE Id IN :jobIds
      ]) {
        jobsById.put(String.valueOf(job.Id), job);
      }
    }

    for (Partner_Application__c application : staleApplications) {
      AsyncApexJob job = jobsById.get(application.Provisioning_Job_Id__c);
      String jobStatus = job == null ? 'not found' : job.Status;

      if (
        job != null &&
        job.Status != 'Completed' &&
        job.Status != 'Failed' &&
        job.Status != 'Aborted'
      ) {
        try {
          System.abortJob(job.Id);
          jobStatus = 'aborted after exceeding the 24-hour timeout';
        } catch (Exception ex) {
          jobStatus = 'timed out; automatic abort failed: ' + ex.getMessage();
        }
      }

      application.Provisioning_Status__c = 'Failed';
      application.Provisioning_Error__c = truncate(
        'Provisioning job ' + jobStatus + '. Retry provisioning.'
      );
      application.Provisioning_Job_Id__c = null;
    }

    update staleApplications;
  }

  private static String truncate(String value) {
    return value.substring(0, Math.min(value.length(), 32768));
  }
}
