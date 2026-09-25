/*
 * Covers LeadDistributionService's two assignment entry points:
 * assignLeadToPartner (manual, caller-supplied partner) and distributeLead
 * (Round Robin, rule-driven). Both must produce a durable
 * Partner_Lead_Assignment__c record, not just Lead field mutation.
 */
@IsTest
private class LeadDistributionServiceTest {
  @IsTest
  static void manualAssignmentCreatesDurableAssignmentRecord() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = unassignedLead();
    insert lead;

    User channelManager = channelManagerUser();

    LeadAssignmentRequestDTO request = new LeadAssignmentRequestDTO();
    request.leadId = lead.Id;
    request.partnerAccountId = partner.Id;
    request.partnerContactId = contact.Id;
    request.notes = 'Manually routed to Partner.';

    System.runAs(channelManager) {
      enableLeads();
      LeadDistributionService.assignLeadToPartner(request);
    }

    Lead updated = [
      SELECT Partner_Account__c, Partner_Contact__c, Lead_Distribution_Status__c
      FROM Lead
      WHERE Id = :lead.Id
    ];
    Assert.areEqual(partner.Id, updated.Partner_Account__c);
    Assert.areEqual('Assigned', updated.Lead_Distribution_Status__c);

    Partner_Lead_Assignment__c assignment = [
      SELECT
        Lead__c,
        Partner_Account__c,
        Partner_Contact__c,
        Status__c,
        Assignment_Strategy__c,
        Active_Assignment_Key__c,
        Version_Number__c
      FROM Partner_Lead_Assignment__c
      WHERE Lead__c = :lead.Id
    ];
    Assert.areEqual(partner.Id, assignment.Partner_Account__c);
    Assert.areEqual('Assigned', assignment.Status__c);
    Assert.areEqual('Manual', assignment.Assignment_Strategy__c);
    Assert.areEqual(
      String.valueOf(lead.Id),
      assignment.Active_Assignment_Key__c
    );
    Assert.areEqual(0, assignment.Version_Number__c);

    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Lead_Distribution_Log__c WHERE Lead__c = :lead.Id]
    );
  }

  @IsTest
  static void manualAssignmentBlockedWhileAnAssignmentIsAlreadyActive() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = unassignedLead();
    insert lead;

    User channelManager = channelManagerUser();

    LeadAssignmentRequestDTO request = new LeadAssignmentRequestDTO();
    request.leadId = lead.Id;
    request.partnerAccountId = partner.Id;

    System.runAs(channelManager) {
      enableLeads();
      LeadDistributionService.assignLeadToPartner(request);

      try {
        LeadDistributionService.assignLeadToPartner(request);
        Assert.fail('Expected a second assignment attempt to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('already has an active assignment')
        );
      }
    }

    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Partner_Lead_Assignment__c WHERE Lead__c = :lead.Id]
    );
  }

  @IsTest
  static void distributeLeadSkipsUnimplementedHigherPriorityRulesAndUsesRoundRobin() {
    // The seeded Lead_Distribution_Rule__mdt records (Territory priority 1
    // through AI Recommendation priority 5) are all active with no
    // criteria, but only Round Robin (priority 4) has an implemented
    // strategy - distributeLead must skip the four unimplemented,
    // higher-priority rules rather than failing on the first match.
    Account partnerA = PartnerSyncTestDataFactory.partnerAccount('Partner A');
    Account partnerB = PartnerSyncTestDataFactory.partnerAccount('Partner B');
    insert new List<Account>{ partnerA, partnerB };
    Lead lead = unassignedLead();
    insert lead;

    User channelManager = channelManagerUser();

    System.runAs(channelManager) {
      enableLeads();
      LeadDistributionService.distributeLead(lead.Id);
    }

    Partner_Lead_Assignment__c assignment = [
      SELECT
        Partner_Account__c,
        Assignment_Strategy__c,
        Distribution_Rule_Key__c,
        Status__c
      FROM Partner_Lead_Assignment__c
      WHERE Lead__c = :lead.Id
    ];
    Assert.areEqual('Round Robin', assignment.Assignment_Strategy__c);
    Assert.areEqual('RoundRobin', assignment.Distribution_Rule_Key__c);
    Assert.areEqual('Assigned', assignment.Status__c);
    Assert.isTrue(
      assignment.Partner_Account__c == partnerA.Id ||
        assignment.Partner_Account__c == partnerB.Id
    );
  }

  @IsTest
  static void distributeLeadRotatesAcrossPartnersOverMultipleLeads() {
    Account partnerA = PartnerSyncTestDataFactory.partnerAccount('Partner A');
    Account partnerB = PartnerSyncTestDataFactory.partnerAccount('Partner B');
    insert new List<Account>{ partnerA, partnerB };

    User channelManager = channelManagerUser();

    System.runAs(channelManager) {
      enableLeads();

      Lead first = unassignedLead();
      insert first;
      LeadDistributionService.distributeLead(first.Id);

      Lead second = unassignedLead();
      insert second;
      LeadDistributionService.distributeLead(second.Id);
    }

    List<Partner_Lead_Assignment__c> assignments = [
      SELECT Partner_Account__c
      FROM Partner_Lead_Assignment__c
      ORDER BY CreatedDate ASC
    ];
    Assert.areEqual(2, assignments.size());
    Assert.areNotEqual(
      assignments[0].Partner_Account__c,
      assignments[1].Partner_Account__c,
      'The second lead should rotate to the partner that did not receive the first.'
    );
  }

  @IsTest
  static void distributeLeadFailsCleanlyWithNoEligiblePartners() {
    Lead lead = unassignedLead();
    insert lead;

    User channelManager = channelManagerUser();

    System.runAs(channelManager) {
      enableLeads();
      try {
        LeadDistributionService.distributeLead(lead.Id);
        Assert.fail('Expected a no-eligible-partner failure.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('No eligible partner'));
      }
    }
  }

  private static Lead unassignedLead() {
    return new Lead(
      LastName = 'Lead',
      Company = 'Customer Prospect',
      Email = 'lead-' + Crypto.getRandomInteger() + '@example.com',
      Status = 'Open - Not Contacted',
      Lead_Distribution_Status__c = 'Pending'
    );
  }

  private static User channelManagerUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    return channelManager;
  }

  private static void enableLeads() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_Leads__c = true)
    );
  }
}
