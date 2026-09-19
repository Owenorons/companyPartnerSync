/**
 * Records the terminal outcome of an asynchronous partner user provisioning
 * attempt back onto the originating Partner_Application__c record. Enqueued
 * by the provisioning worker after it succeeds or fails.
 */
public without sharing class PartnerProvisioningStatusQueueable implements Queueable {
  private Id applicationId;
  private Id provisionedUserId;
  private String errorMessage;
  private String provisioningJobId;

  /**
   * Creates a queueable that writes back a provisioning attempt's outcome.
   *
   * @param applicationId Id of the Partner_Application__c the outcome should be recorded against.
   * @param provisionedUserId Id of the provisioned partner User, or null if provisioning failed.
   * @param errorMessage Failure detail to record when provisionedUserId is null; ignored otherwise.
   * @param provisioningJobId Id of the provisioning job that produced this outcome, used to guard against a stale/superseded write; null skips the check.
   */
  public PartnerProvisioningStatusQueueable(
    Id applicationId,
    Id provisionedUserId,
    String errorMessage,
    String provisioningJobId
  ) {
    this.applicationId = applicationId;
    this.provisionedUserId = provisionedUserId;
    this.errorMessage = errorMessage;
    this.provisioningJobId = provisioningJobId;
  }

  /**
   * Writes the provisioning outcome onto the application, provided it is
   * still Queued and (when a job id was supplied) still matches the job
   * that queued it — otherwise the write is skipped as stale/superseded.
   *
   * @param context The queueable execution context provided by the platform.
   */
  public void execute(QueueableContext context) {
    List<Partner_Application__c> applications = [
      SELECT Id, Provisioning_Status__c, Provisioning_Job_Id__c
      FROM Partner_Application__c
      WHERE Id = :applicationId
      LIMIT 1
      FOR UPDATE
    ];

    if (applications.isEmpty()) {
      return;
    }

    Partner_Application__c application = applications[0];
    if (
      application.Provisioning_Status__c != 'Queued' ||
      (provisioningJobId != null &&
      application.Provisioning_Job_Id__c != provisioningJobId)
    ) {
      return;
    }

    if (provisionedUserId != null) {
      application.Provisioning_Status__c = 'Complete';
      application.Provisioning_Error__c = null;
      application.Provisioned_User__c = provisionedUserId;
      application.Provisioned_On__c = System.now();
    } else {
      application.Provisioning_Status__c = 'Failed';
      application.Provisioning_Error__c = String.isBlank(errorMessage)
        ? 'Partner user provisioning failed.'
        : errorMessage.substring(0, Math.min(errorMessage.length(), 32768));
    }

    application.Provisioning_Job_Id__c = null;

    update application;
  }
}
