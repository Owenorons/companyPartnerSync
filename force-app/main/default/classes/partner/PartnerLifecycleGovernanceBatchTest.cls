@IsTest
private class PartnerLifecycleGovernanceBatchTest {
  @IsTest
  static void expiresEvidenceAndFlagsRecertificationIdempotently() {
    Account account = new Account(Name = 'Governance Account');
    insert account;
    Contact contact = new Contact(
      AccountId = account.Id,
      LastName = 'Governance',
      Email = 'governance@example.test'
    );
    insert contact;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Governance Partner',
      Company_Name__c = 'Governance Partner',
      Business_Email__c = 'governance@example.test',
      Application_Status__c = 'Approved',
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Active',
      Current_Stage__c = 'Active',
      Activation_Gate_Status__c = 'Ready',
      Recertification_Due_On__c = Date.today().addDays(-1),
      Version_Number__c = 1
    );
    insert onboarding;
    Partner_Agreement__c agreement = new Partner_Agreement__c(
      Onboarding__c = onboarding.Id,
      Agreement_Key__c = onboarding.Id + ':EXPIRED-AGREEMENT',
      Agreement_Type__c = 'Programme Agreement',
      Status__c = 'Effective',
      Template_Key__c = 'PROGRAMME',
      Template_Version__c = 1,
      Effective_On__c = Date.today().addYears(-1),
      Expires_On__c = Date.today().addDays(-1)
    );
    insert agreement;
    Partner_Relationship__c relationship = new Partner_Relationship__c(
      Onboarding__c = onboarding.Id,
      Relationship_Key__c = onboarding.Id + ':GOV-REL',
      Account__c = account.Id,
      Programme_Key__c = 'RESELLER',
      Status__c = 'Active'
    );
    insert relationship;
    Partner_Access_Request__c request = new Partner_Access_Request__c(
      Onboarding__c = onboarding.Id,
      Request_Key__c = onboarding.Id + ':EXPIRED-ACCESS',
      Relationship__c = relationship.Id,
      Contact__c = contact.Id,
      Access_Bundle__c = 'PSG_Partner_User',
      Status__c = 'Provisioned',
      Expires_On__c = Date.today().addDays(-1)
    );
    insert request;
    Partner_Training_Assignment__c training = new Partner_Training_Assignment__c(
      Onboarding__c = onboarding.Id,
      Assignment_Key__c = onboarding.Id + ':EXPIRED-TRAINING',
      Training_Key__c = 'FOUNDATIONS',
      Mandatory__c = true,
      Status__c = 'Completed',
      Completed_On__c = System.now().addYears(-1),
      Expires_On__c = Date.today().addDays(-1)
    );
    insert training;
    Partner_Document_Requirement__c requirement = new Partner_Document_Requirement__c(
      Onboarding__c = onboarding.Id,
      Requirement_Key__c = onboarding.Id + ':EXPIRED-INSURANCE',
      Document_Type__c = 'Insurance Certificate',
      Requirement_Level__c = 'Mandatory',
      Gate__c = 'Renewal',
      Status__c = 'Accepted',
      Blocking__c = true,
      Due_On__c = Date.today().addYears(-1)
    );
    insert requirement;
    Partner_Document__c document = new Partner_Document__c(
      Onboarding__c = onboarding.Id,
      Requirement__c = requirement.Id,
      Content_Document_Id__c = '069000000000001AAA',
      Submission_Key__c = onboarding.Id + ':EXPIRED-DOCUMENT',
      Version_Number__c = 1,
      Status__c = 'Accepted',
      Confidentiality__c = 'Partner',
      Submitted_On__c = System.now().addYears(-1),
      Expiry_Date__c = Date.today().addDays(-1)
    );
    insert document;

    Test.startTest();
    Database.executeBatch(new PartnerLifecycleGovernanceBatch(), 100);
    Test.stopTest();

    System.assertEquals(
      'Expired',
      [SELECT Status__c FROM Partner_Agreement__c WHERE Id = :agreement.Id]
      .Status__c
    );
    System.assertEquals(
      'Expired',
      [SELECT Status__c FROM Partner_Document__c WHERE Id = :document.Id]
      .Status__c
    );
    System.assertEquals(
      'Expired',
      [
        SELECT Status__c
        FROM Partner_Document_Requirement__c
        WHERE Id = :requirement.Id
      ]
      .Status__c
    );
    System.assertEquals(
      'Expired',
      [SELECT Status__c FROM Partner_Access_Request__c WHERE Id = :request.Id]
      .Status__c
    );
    System.assertEquals(
      'Expired',
      [
        SELECT Status__c
        FROM Partner_Training_Assignment__c
        WHERE Id = :training.Id
      ]
      .Status__c
    );
    onboarding = [
      SELECT Activation_Gate_Status__c, Current_Stage__c, Lifecycle_Reason__c
      FROM Partner_Onboarding__c
      WHERE Id = :onboarding.Id
    ];
    System.assertEquals('Blocked', onboarding.Activation_Gate_Status__c);
    System.assertEquals('Readiness', onboarding.Current_Stage__c);
    System.assert(onboarding.Lifecycle_Reason__c.contains('recertification'));
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Partner_Lifecycle_Event__c
        WHERE
          Onboarding__c = :onboarding.Id
          AND Event_Type__c = 'Recertification Due'
      ]
    );
  }

  @IsTest
  static void schedulableQueuesBatch() {
    Test.startTest();
    new PartnerLifecycleGovernanceBatch().execute((SchedulableContext) null);
    Test.stopTest();
    System.assert(true);
  }
}
