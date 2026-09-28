/*
 * Covers PartnerOperationsCommandCenterController.getOperationsSummary():
 * each count reflects a real fixture row in the matching state, and an
 * external partner user is rejected.
 */
@IsTest
private class PartnerOperationsCommandCenterControllerTest {
  @IsTest
  static void summaryReflectsRealFixtureRowsInEachState() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    OperationsSummaryDTO summary;
    System.runAs(internalUser) {
      summary = PartnerOperationsCommandCenterController.getOperationsSummary();
    }

    Assert.areEqual(1, summary.pendingHandoffCount);
    Assert.areEqual(1, summary.atRiskEngagementCount);
    Assert.areEqual(1, summary.renewalsDueCount);
    Assert.areEqual(1, summary.partnerConfirmationRequiredCount);
    Assert.areEqual(1, summary.openExpansionCount);
    Assert.areEqual(1, summary.pendingReassignmentCount);
    Assert.areEqual(1, summary.openDisputeCount);
    Assert.areEqual(1, summary.proposedRecommendationCount);
  }

  @IsTest
  static void externalPartnerUserIsRejected() {
    Fixture fixture = createFixture();
    User partnerUser = TestUserFactory.createExternalUser(fixture.contact.Id);

    System.runAs(partnerUser) {
      try {
        PartnerOperationsCommandCenterController.getOperationsSummary();
        Assert.fail('Expected an external partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Operations Summary Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Operations Summary Customer'
    );
    insert new List<Account>{ partner, customer };
    fixture.contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert fixture.contact;

    insert new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Pending Handoff',
      Health_Status__c = 'Not Assessed',
      Version_Number__c = 0
    );

    Customer_Success_Engagement__c atRiskEngagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'At Risk',
      Version_Number__c = 0
    );
    insert atRiskEngagement;

    insert new Partner_Renewal__c(
      Customer_Success_Engagement__c = atRiskEngagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Review Required',
      Renewal_Health__c = 'At Risk',
      Version_Number__c = 0
    );

    insert new Partner_Renewal__c(
      Customer_Success_Engagement__c = atRiskEngagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Partner Confirmation Required',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );

    insert new Partner_Expansion__c(
      Customer_Success_Engagement__c = atRiskEngagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Expansion_Type__c = 'Seat Increase',
      Status__c = 'Identified',
      Version_Number__c = 0
    );

    insert new Partner_Reassignment__c(
      Target_Object__c = 'Partner_Renewal__c',
      Target_Record_Id__c = atRiskEngagement.Id,
      Current_Partner__c = partner.Id,
      Requested_Partner__c = partner.Id,
      Reason__c = 'Test reassignment.',
      Status__c = 'Requested',
      Version_Number__c = 0
    );

    insert new Partner_Revenue_Dispute__c(
      Partner_Account__c = partner.Id,
      Dispute_Type__c = 'Missing Revenue',
      Status__c = 'Open',
      Description__c = 'Test dispute.',
      Submitted_On__c = System.now()
    );

    AI_Interaction__c interaction = new AI_Interaction__c(
      Use_Case_Key__c = 'RenewalRiskAdvisor',
      Status__c = 'Succeeded'
    );
    insert interaction;
    insert new AI_Recommendation__c(
      Interaction__c = interaction.Id,
      Recommended_Action_Key__c = 'RequestRenewalReview',
      Recommendation_Text__c = 'Test recommendation.',
      Status__c = 'Proposed'
    );

    return fixture;
  }

  private class Fixture {
    Contact contact;
  }
}
