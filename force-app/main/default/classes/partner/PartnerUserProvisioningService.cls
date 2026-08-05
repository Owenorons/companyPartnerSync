/*
 * Starts login provisioning after an administrator has enabled the approved
 * Account as a Salesforce partner account. User creation is asynchronous to
 * keep setup-object DML separate from application/Account/Contact DML.
 */
public with sharing class PartnerUserProvisioningService {
  public static void requestProvisioning(Id applicationId) {
    PartnerPermissionService.assertCanApprovePartnerApplications();
    SecurityUtil.assertUpdateable(Partner_Application__c.SObjectType);

    Partner_Application__c application = PartnerApplicationSelector.selectForDecisionById(
      applicationId
    );

    if (
      application.Application_Status__c != 'Approved' ||
      application.Created_Account__c == null ||
      application.Created_Contact__c == null
    ) {
      throw new PartnerSyncHandledException(
        'Only an approved application with created partner records can be provisioned.'
      );
    }

    if (application.Provisioned_User__c != null) {
      throw new PartnerSyncHandledException(
        'Partner access has already been provisioned.'
      );
    }

    if (application.Provisioning_Status__c == 'Queued') {
      throw new PartnerSyncHandledException(
        'Partner access provisioning is already queued.'
      );
    }

    Account partnerAccount = [
      SELECT Id, IsPartner
      FROM Account
      WHERE Id = :application.Created_Account__c
      WITH USER_MODE
      LIMIT 1
    ];

    if (!partnerAccount.IsPartner) {
      throw new PartnerSyncHandledException(
        'Enable the created Account as a Partner before provisioning access.'
      );
    }

    Id provisioningJobId = System.enqueueJob(
      new PartnerUserProvisioningQueueable(
        application.Id,
        application.Created_Contact__c
      )
    );

    application.Provisioning_Status__c = 'Queued';
    application.Provisioning_Error__c = null;
    application.Provisioning_Job_Id__c = String.valueOf(provisioningJobId);
    application.Provisioning_Started_On__c = System.now();
    update SecurityUtil.stripForUpdate(new List<SObject>{ application });
  }
}
