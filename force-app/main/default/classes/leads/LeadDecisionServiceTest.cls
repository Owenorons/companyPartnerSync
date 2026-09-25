/*
 * Covers LeadDecisionService.processDecision() as a facade over
 * LeadAssignmentCommandService: it must keep its original Lead-Id-keyed
 * signature (so psPartnerLeads is unaffected) while actually deciding
 * through the new durable Partner_Lead_Assignment__c aggregate.
 */
@IsTest
private class LeadDecisionServiceTest {
  @IsTest
  static void acceptDecisionDelegatesToTheActiveAssignment() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;
    insert new Partner_Lead_Assignment__c(
      Lead__c = lead.Id,
      Partner_Account__c = partner.Id,
      Partner_Contact__c = contact.Id,
      Status__c = 'Assigned',
      Assignment_Strategy__c = 'Manual',
      Assigned_On__c = System.now(),
      Active_Assignment_Key__c = String.valueOf(lead.Id),
      Version_Number__c = 0
    );

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    LeadDecisionRequestDTO request = new LeadDecisionRequestDTO();
    request.leadId = lead.Id;
    request.decision = 'Accepted';

    System.runAs(partnerUser) {
      enableLeads();
      LeadDecisionService.processDecision(request);
    }

    Assert.areEqual(
      'Accepted',
      [SELECT Lead_Distribution_Status__c FROM Lead WHERE Id = :lead.Id]
      .Lead_Distribution_Status__c
    );
    Assert.areEqual(
      'Accepted',
      [
        SELECT Status__c
        FROM Partner_Lead_Assignment__c
        WHERE Lead__c = :lead.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void decisionOnALeadWithNoActiveAssignmentFailsCleanly() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    lead.Lead_Distribution_Status__c = 'Rejected';
    insert lead;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    LeadDecisionRequestDTO request = new LeadDecisionRequestDTO();
    request.leadId = lead.Id;
    request.decision = 'Accepted';

    System.runAs(partnerUser) {
      enableLeads();
      try {
        LeadDecisionService.processDecision(request);
        Assert.fail(
          'Expected a lead with no active assignment to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage()
            .contains('Only assigned leads can be accepted or rejected.')
        );
      }
    }
  }

  private static void enableLeads() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_Leads__c = true)
    );
  }
}
