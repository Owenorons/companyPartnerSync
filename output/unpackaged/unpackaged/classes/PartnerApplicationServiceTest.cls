/*
 * Package-isolated coverage for application submission, duplicate detection,
 * and input validation. Guest-user access is a subscriber integration concern
 * because the managed core package doesn't own the customer's site or guest
 * profile.
 */
@IsTest
private class PartnerApplicationServiceTest {
  @IsTest
  static void submitApplicationCreatesCoreRecord() {
    PartnerApplicationRequestDTO request = new PartnerApplicationRequestDTO();
    request.companyName = 'Fernvale Distribution';
    request.businessEmail = 'hello@fernvale-test.example.com';
    request.phone = '555-0142';
    request.website = 'https://fernvale-test.example.com';
    request.country = 'Australia';
    request.region = 'ANZ';
    request.requestedTier = 'Gold';
    request.partnerType = 'Reseller';
    request.submittedByContactName = 'Jules Kestrel';
    request.submittedByEmail = 'jules@fernvale-test.example.com';

    PartnerApplicationResultDTO result;

    Test.startTest();
    result = PartnerApplicationController.submitApplication(request);
    Test.stopTest();

    System.assertNotEquals(
      null,
      result.applicationId,
      'submitApplication should return the new record\'s Id.'
    );
    System.assertEquals('Submitted', result.status);
    System.assertNotEquals(
      null,
      result.applicationNumber,
      'applicationNumber should be populated from Application_Number__c.'
    );

    // Re-query to verify persistence and catch silent security field stripping.
    Partner_Application__c inserted = [
      SELECT
        Name,
        Company_Name__c,
        Business_Email__c,
        Phone__c,
        Website__c,
        Country__c,
        Region__c,
        Requested_Tier__c,
        Partner_Type__c,
        Submitted_By_Contact_Name__c,
        Submitted_By_Email__c,
        Application_Status__c,
        Decision__c,
        Source__c,
        Active_Company_Key__c,
        Active_Email_Key__c,
        Application_Number__c
      FROM Partner_Application__c
      WHERE Id = :result.applicationId
    ];

    System.assertEquals('Fernvale Distribution', inserted.Name);
    System.assertEquals('Fernvale Distribution', inserted.Company_Name__c);
    System.assertEquals(
      'hello@fernvale-test.example.com',
      inserted.Business_Email__c
    );
    System.assertEquals('555-0142', inserted.Phone__c);
    System.assertEquals('Gold', inserted.Requested_Tier__c);
    System.assertEquals('Reseller', inserted.Partner_Type__c);
    System.assertEquals('Jules Kestrel', inserted.Submitted_By_Contact_Name__c);
    System.assertEquals(
      'jules@fernvale-test.example.com',
      inserted.Submitted_By_Email__c
    );
    System.assertEquals('Submitted', inserted.Application_Status__c);
    System.assertEquals('Pending', inserted.Decision__c);
    System.assertEquals('Website', inserted.Source__c);
    System.assertEquals('fernvaledistribution', inserted.Active_Company_Key__c);
    System.assertEquals(
      'hello@fernvale-test.example.com',
      inserted.Active_Email_Key__c
    );
    System.assertEquals(
      inserted.Application_Number__c,
      result.applicationNumber
    );
  }

  @IsTest
  static void submitApplicationRejectsDuplicateCompanyOrEmail() {
    PartnerApplicationRequestDTO request = new PartnerApplicationRequestDTO();
    request.companyName = 'Duplicate Test Co';
    request.businessEmail = 'first@duplicate-test.example.com';
    request.requestedTier = 'Silver';
    request.partnerType = 'Distributor';
    request.submittedByEmail = 'submitter@duplicate-test.example.com';

    PartnerApplicationController.submitApplication(request);

    PartnerApplicationRequestDTO secondRequest = new PartnerApplicationRequestDTO();
    secondRequest.companyName = 'Duplicate Test Co';
    secondRequest.businessEmail = 'first@duplicate-test.example.com';
    secondRequest.requestedTier = 'Platinum';
    secondRequest.partnerType = 'Agent';
    secondRequest.submittedByEmail = 'second-submitter@duplicate-test.example.com';

    Boolean threw = false;

    Test.startTest();
    try {
      PartnerApplicationController.submitApplication(secondRequest);
    } catch (AuraHandledException ex) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(
      true,
      threw,
      'A second application for the same company/email should be rejected.'
    );
  }

  @IsTest
  static void submitApplicationValidatesRequiredFields() {
    PartnerApplicationRequestDTO request = new PartnerApplicationRequestDTO();
    request.businessEmail = 'no-company-name@example.com';
    request.requestedTier = 'Gold';
    request.partnerType = 'Reseller';
    request.submittedByEmail = 'submitter@example.com';
    // companyName intentionally left blank.

    Boolean threw = false;

    Test.startTest();
    try {
      PartnerApplicationController.submitApplication(request);
    } catch (AuraHandledException ex) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(
      true,
      threw,
      'A request with no company name should be rejected.'
    );
  }

  @IsTest
  static void submitApplicationRejectsInvalidPicklistValuesAndEmails() {
    PartnerApplicationRequestDTO request = new PartnerApplicationRequestDTO();
    request.companyName = 'Invalid Input Co';
    request.businessEmail = 'not-an-email';
    request.requestedTier = 'Diamond';
    request.partnerType = 'Unknown';
    request.submittedByEmail = 'also-invalid';

    Boolean threw = false;

    try {
      PartnerApplicationService.submitApplication(request);
    } catch (PartnerSyncHandledException ex) {
      threw = true;
      System.assertEquals('Business email is invalid.', ex.getMessage());
    }

    System.assertEquals(true, threw, 'Invalid input should be rejected.');
  }

  @IsTest
  static void reviewerListsViewsAndClaimsApplicationThroughController() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(manager) {
      Partner_Application__c application = new Partner_Application__c(
        Name = 'Review Coverage Partner',
        Company_Name__c = 'Review Coverage Partner',
        Business_Email__c = 'review-coverage@example.com',
        Requested_Tier__c = 'Gold',
        Partner_Type__c = 'Reseller',
        Submitted_By_Contact_Name__c = 'Review Contact',
        Submitted_By_Email__c = 'review-contact@example.com',
        Application_Status__c = 'Submitted',
        Decision__c = 'Pending',
        Submitted_On__c = System.now()
      );
      insert application;

      List<PartnerApplicationListDTO> pending = PartnerApplicationController.getPendingApplications();
      Assert.areEqual(1, pending.size());
      Assert.areEqual(application.Id, pending[0].applicationId);

      PartnerApplicationDetailDTO beforeClaim = PartnerApplicationController.getApplicationDetail(
        application.Id
      );
      Assert.isTrue(beforeClaim.canClaim);
      Assert.isFalse(beforeClaim.canDecide);

      PartnerApplicationController.claimApplication(application.Id);

      PartnerApplicationDetailDTO afterClaim = PartnerApplicationController.getApplicationDetail(
        application.Id
      );
      Assert.areEqual('Under Review', afterClaim.status);
      Assert.areEqual(manager.Id, afterClaim.assignedReviewerId);
      Assert.isTrue(afterClaim.isAssignedToCurrentUser);
      Assert.isTrue(afterClaim.canDecide);
    }
  }

  @IsTest
  static void reviewerSeesWebsiteAndContactEmailMatches() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(manager) {
      Account existing = new Account(
        Name = 'Different Trading Name',
        Website = 'https://matched.example.com'
      );
      insert existing;
      insert new Contact(
        AccountId = existing.Id,
        LastName = 'Existing Contact',
        Email = 'existing-contact@matched.example.com'
      );
      Partner_Application__c application = new Partner_Application__c(
        Company_Name__c = 'New Applicant Name',
        Website__c = 'https://matched.example.com',
        Submitted_By_Email__c = 'existing-contact@matched.example.com'
      );

      List<PartnerApplicationMatchDTO> matches = PartnerApplicationMatchSelector.findPotentialMatches(
        application
      );
      Assert.areEqual(2, matches.size());
      Assert.areEqual('Website matches', matches[0].matchReason);
      Assert.areEqual('Contact email matches', matches[1].matchReason);
    }
  }
}
