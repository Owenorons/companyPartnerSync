public without sharing class PartnerProvisioningStatusQueueable implements Queueable {
  private Id applicationId;
  private Id provisionedUserId;
  private String errorMessage;
  private String provisioningJobId;

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
