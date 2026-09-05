@IsTest
private class PartnerOperationalAlertServiceTest {
  @IsTest
  static void scansDeduplicatesAcknowledgesAndResolvesAlerts() {
    Partner_Onboarding__c onboarding = createOnboarding();
    Partner_Onboarding_Task__c task = new Partner_Onboarding_Task__c(
      Onboarding__c = onboarding.Id,
      Title__c = 'Complete verification',
      Status__c = 'In Progress',
      Due_On__c = System.now().addDays(-1)
    );
    Partner_Document_Requirement__c requirement = new Partner_Document_Requirement__c(
      Onboarding__c = onboarding.Id,
      Requirement_Key__c = onboarding.Id + ':INSURANCE',
      Document_Type__c = 'Insurance Certificate',
      Requirement_Level__c = 'Mandatory',
      Gate__c = 'Activation',
      Status__c = 'Awaiting Submission',
      Blocking__c = true,
      Due_On__c = Date.today().addDays(-1)
    );
    insert task;
    insert requirement;
    Partner_Document__c document = new Partner_Document__c(
      Onboarding__c = onboarding.Id,
      Requirement__c = requirement.Id,
      Content_Document_Id__c = '069000000000001AAA',
      Submission_Key__c = onboarding.Id + ':DOCUMENT',
      Version_Number__c = 1,
      Status__c = 'Accepted',
      Confidentiality__c = 'Partner',
      Submitted_On__c = System.now(),
      Expiry_Date__c = Date.today().addDays(-1)
    );
    insert document;
    Partner_Agreement__c agreement = new Partner_Agreement__c(
      Onboarding__c = onboarding.Id,
      Agreement_Key__c = onboarding.Id + ':AGREEMENT',
      Agreement_Type__c = 'Programme Agreement',
      Status__c = 'Effective',
      Template_Key__c = 'PROGRAMME',
      Template_Version__c = 1
    );
    insert agreement;
    Partner_Signature_Event__c signatureEvent = new Partner_Signature_Event__c(
      Agreement__c = agreement.Id,
      Provider_Event_Id__c = 'event-1',
      Event_Type__c = 'Signature Failed',
      Provider_Occurred_On__c = System.now(),
      Payload_Hash__c = 'hash-1',
      Signature_Verified__c = true,
      Processing_Status__c = 'Failed'
    );
    insert signatureEvent;

    List<Partner_Operational_Alert__c> firstScan = PartnerOperationalAlertService.scan();
    Assert.areEqual(5, firstScan.size());
    List<Partner_Operational_Alert__c> secondScan = PartnerOperationalAlertService.scan();
    Assert.areEqual(5, secondScan.size());
    Assert.areEqual(2, secondScan[0].Occurrence_Count__c);

    PartnerOperationalAlertService.testManageAuthority = true;
    Partner_Operational_Alert__c acknowledged = PartnerOperationalAlertService.acknowledge(
      firstScan[0].Id
    );
    Assert.areEqual('Acknowledged', acknowledged.Status__c);

    signatureEvent.Processing_Status__c = 'Processed';
    task.Status__c = 'Complete';
    requirement.Status__c = 'Accepted';
    document.Expiry_Date__c = Date.today().addDays(60);
    onboarding.Status__c = 'Onboarding';
    update signatureEvent;
    update task;
    update requirement;
    update document;
    update onboarding;

    Assert.areEqual(0, PartnerOperationalAlertService.scan().size());
    Assert.areEqual(
      5,
      [
        SELECT COUNT()
        FROM Partner_Operational_Alert__c
        WHERE Status__c = 'Resolved'
      ]
    );
    new PartnerOperationalAlertService().execute(null);
  }

  @IsTest
  static void rejectsAcknowledgementWithoutAuthority() {
    Partner_Operational_Alert__c alert = new Partner_Operational_Alert__c(
      Alert_Key__c = 'AUTHORITY-TEST',
      Alert_Type__c = 'Overdue Work',
      Severity__c = 'High',
      Status__c = 'Open',
      Source_Record_Id__c = UserInfo.getUserId(),
      Message__c = 'Test alert',
      Occurrence_Count__c = 1,
      First_Detected_On__c = System.now(),
      Last_Detected_On__c = System.now()
    );
    insert alert;
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      try {
        PartnerOperationalAlertService.acknowledge(alert.Id);
        Assert.fail('Expected authority rejection.');
      } catch (PartnerOperationalAlertService.OperationalAlertException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }
  }

  private static Partner_Onboarding__c createOnboarding() {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Alert Applicant',
      Company_Name__c = 'Alert Applicant',
      Business_Email__c = 'alert@example.test',
      Application_Status__c = 'Approved'
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
    return onboarding;
  }
}
