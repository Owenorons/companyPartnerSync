/*
 * Verifies MDFService.submitRequest()'s approval-plan wiring: a submission
 * generates a current Approval_Plan__c/Approval__c scoped to
 * 'MDF_Request__c', with the target amount/label/version the caller is
 * responsible for supplying since the generic engine never queries the
 * target object itself.
 */
@IsTest
private class MDFServiceTest {
  @IsTest
  static void submittingGeneratesAnMdfScopedApprovalPlan() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_MDF__c = true)
    );

    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    MDFRequestDTO request = new MDFRequestDTO();
    request.requestType = 'Webinar';
    request.campaignName = 'Launch Webinar';
    request.requestedAmount = 2000;
    request.startDate = Date.today();
    request.endDate = Date.today().addDays(10);

    System.runAs(partnerUser) {
      MDFService.submitRequest(request);
    }

    MDF_Request__c mdfRequest = [
      SELECT Id, Name
      FROM MDF_Request__c
      WHERE Partner_Account__c = :partner.Id
      LIMIT 1
    ];

    Approval_Plan__c plan = [
      SELECT Status__c, Target_Label__c, Target_Version__c
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = 'MDF_Request__c'
        AND Target_Record_Id__c = :mdfRequest.Id
        AND Current__c = TRUE
    ];
    Assert.areEqual('Pending', plan.Status__c);
    Assert.areEqual(0, plan.Target_Version__c);
    Assert.isTrue(plan.Target_Label__c.startsWith(mdfRequest.Name));
    Assert.isTrue(plan.Target_Label__c.contains('Launch Webinar'));

    Approval__c step = [
      SELECT Status__c, Target_Amount__c, Approver_Permission_Set__c
      FROM Approval__c
      WHERE
        Object_Name__c = 'MDF_Request__c'
        AND Target_Record_Id__c = :mdfRequest.Id
      LIMIT 1
    ];
    Assert.areEqual('Pending', step.Status__c);
    Assert.areEqual(2000, step.Target_Amount__c);
    Assert.areEqual(
      'PartnerSync_MDF_Reviewer',
      step.Approver_Permission_Set__c
    );
  }

  @IsTest
  static void resubmitRegeneratesPlanAndReturnsRequestToSubmitted() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_MDF__c = true)
    );

    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    MDF_Request__c request = PartnerSyncTestDataFactory.mdfRequest(
      partner.Id,
      contact.Id
    );
    request.Status__c = 'Needs Information';
    request.Return_Reason__c = 'Missing sponsor letter.';
    insert request;

    System.runAs(partnerUser) {
      MDFService.resubmitRequest(request.Id);
    }

    MDF_Request__c updated = [
      SELECT Status__c, Return_Reason__c
      FROM MDF_Request__c
      WHERE Id = :request.Id
    ];
    Assert.areEqual('Submitted', updated.Status__c);
    Assert.isNull(updated.Return_Reason__c);

    Approval_Plan__c plan = [
      SELECT Status__c
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = 'MDF_Request__c'
        AND Target_Record_Id__c = :request.Id
        AND Current__c = TRUE
    ];
    Assert.areEqual('Pending', plan.Status__c);

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Audit_Log__c
        WHERE
          Object_Name__c = 'MDF_Request__c'
          AND Record_Id__c = :request.Id
          AND Action__c = 'Resubmit'
      ]
    );
  }

  @IsTest
  static void resubmitRejectsNonOwningPartner() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_MDF__c = true)
    );

    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;
    Contact owningContact = PartnerSyncTestDataFactory.partnerContact(
      owningPartner.Id
    );
    insert owningContact;
    MDF_Request__c request = PartnerSyncTestDataFactory.mdfRequest(
      owningPartner.Id,
      owningContact.Id
    );
    request.Status__c = 'Needs Information';
    insert request;

    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);
    TestUserFactory.assignPermissionSet(
      otherPartnerUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(otherPartnerUser) {
      try {
        MDFService.resubmitRequest(request.Id);
        Assert.fail('Expected a non-owning partner to be rejected.');
      } catch (Exception expected) {
        Assert.isTrue(true);
      }
    }

    Assert.areEqual(
      'Needs Information',
      [SELECT Status__c FROM MDF_Request__c WHERE Id = :request.Id].Status__c
    );
  }

  @IsTest
  static void resubmitRejectsRequestNotAwaitingInformation() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_MDF__c = true)
    );

    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    MDF_Request__c request = PartnerSyncTestDataFactory.mdfRequest(
      partner.Id,
      contact.Id
    );
    request.Status__c = 'Under Review';
    insert request;

    System.runAs(partnerUser) {
      try {
        MDFService.resubmitRequest(request.Id);
        Assert.fail('Expected rejection of a request not Needs Information.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('Needs Information'));
      }
    }

    Assert.areEqual(
      'Under Review',
      [SELECT Status__c FROM MDF_Request__c WHERE Id = :request.Id].Status__c
    );
  }
}
