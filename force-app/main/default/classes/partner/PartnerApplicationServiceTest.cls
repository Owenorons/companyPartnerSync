/*
 * Covers the partner application submission flow end-to-end as the actual
 * Experience Cloud Guest User (not an internal test user), plus the
 * duplicate-detection and required-field validation paths.
 */
@IsTest
private class PartnerApplicationServiceTest {
  @IsTest
  static void submitApplicationCreatesRecordAsGuestUser() {
    List<User> guestUsers = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'PartnerSync Portal Profile'
      LIMIT 1
    ];

    System.assert(
      !guestUsers.isEmpty(),
      'No Guest User found for the "PartnerSync Portal Profile" profile. ' +
        'The Experience Cloud site needs to be published at least once so a ' +
        'Guest User is provisioned before this test can run.'
    );

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

    System.runAs(guestUsers[0]) {
      Test.startTest();
      result = PartnerApplicationController.submitApplication(request);
      Test.stopTest();
    }

    System.assertNotEquals(
      null,
      result.applicationId,
      'submitApplication should return the new record\'s Id as a Guest User.'
    );
    System.assertEquals('Submitted', result.status);
    System.assertNotEquals(
      null,
      result.applicationNumber,
      'applicationNumber should be populated from Application_Number__c.'
    );

    // Query as the (privileged) test-running user, not the guest, so this
    // confirms what was actually persisted rather than what the guest can
    // merely read back — catches silent field-stripping from missing FLS.
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
}
