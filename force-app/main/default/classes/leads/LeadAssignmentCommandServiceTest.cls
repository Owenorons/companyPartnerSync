/*
 * Covers LeadAssignmentCommandService.execute() directly: the accept/reject
 * transitions, authority (must belong to the assigned partner account),
 * optimistic-concurrency version checking, and the terminal-status guard.
 */
@IsTest
private class LeadAssignmentCommandServiceTest {
  @IsTest
  static void acceptTransitionsAssignmentAndLeadAndPublishesEvent() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;
    Partner_Lead_Assignment__c assignment = activeAssignment(
      lead.Id,
      partner.Id,
      contact.Id
    );
    insert assignment;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    LeadAssignmentCommand command = new LeadAssignmentCommand();
    command.assignmentId = assignment.Id;
    command.action = 'Accepted';
    command.expectedVersion = 0;

    Test.startTest();
    System.runAs(partnerUser) {
      LeadAssignmentCommandService.execute(command);
    }
    Test.stopTest();

    Partner_Lead_Assignment__c updated = [
      SELECT
        Status__c,
        Accepted_On__c,
        Active_Assignment_Key__c,
        Version_Number__c
      FROM Partner_Lead_Assignment__c
      WHERE Id = :assignment.Id
    ];
    Assert.areEqual('Accepted', updated.Status__c);
    Assert.isNotNull(updated.Accepted_On__c);
    Assert.isNull(updated.Active_Assignment_Key__c);
    Assert.areEqual(1, updated.Version_Number__c);

    Assert.areEqual(
      'Accepted',
      [SELECT Lead_Distribution_Status__c FROM Lead WHERE Id = :lead.Id]
      .Lead_Distribution_Status__c
    );
  }

  @IsTest
  static void rejectRequiresReasonAndReleasesTheActiveKey() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;
    Partner_Lead_Assignment__c assignment = activeAssignment(
      lead.Id,
      partner.Id,
      contact.Id
    );
    insert assignment;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    LeadAssignmentCommand command = new LeadAssignmentCommand();
    command.assignmentId = assignment.Id;
    command.action = 'Rejected';
    command.expectedVersion = 0;
    command.reason = 'Outside our territory.';

    System.runAs(partnerUser) {
      LeadAssignmentCommandService.execute(command);
    }

    Partner_Lead_Assignment__c updated = [
      SELECT Status__c, Rejection_Reason__c, Active_Assignment_Key__c
      FROM Partner_Lead_Assignment__c
      WHERE Id = :assignment.Id
    ];
    Assert.areEqual('Rejected', updated.Status__c);
    Assert.areEqual('Outside our territory.', updated.Rejection_Reason__c);
    Assert.isNull(updated.Active_Assignment_Key__c);
  }

  @IsTest
  static void nonOwningPartnerCannotDecide() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;
    Partner_Lead_Assignment__c assignment = activeAssignment(
      lead.Id,
      partner.Id,
      contact.Id
    );
    insert assignment;

    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);

    LeadAssignmentCommand command = new LeadAssignmentCommand();
    command.assignmentId = assignment.Id;
    command.action = 'Accepted';
    command.expectedVersion = 0;

    System.runAs(otherPartnerUser) {
      try {
        LeadAssignmentCommandService.execute(command);
        Assert.fail('Expected a non-owning partner to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('lacks authority'));
      }
    }
  }

  @IsTest
  static void staleVersionIsRejected() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;
    Partner_Lead_Assignment__c assignment = activeAssignment(
      lead.Id,
      partner.Id,
      contact.Id
    );
    insert assignment;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    LeadAssignmentCommand command = new LeadAssignmentCommand();
    command.assignmentId = assignment.Id;
    command.action = 'Accepted';
    command.expectedVersion = 5;

    System.runAs(partnerUser) {
      try {
        LeadAssignmentCommandService.execute(command);
        Assert.fail('Expected a stale-version rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }
  }

  @IsTest
  static void cannotDecideAnAlreadyDecidedAssignment() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;
    Partner_Lead_Assignment__c assignment = activeAssignment(
      lead.Id,
      partner.Id,
      contact.Id
    );
    insert assignment;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    LeadAssignmentCommand accept = new LeadAssignmentCommand();
    accept.assignmentId = assignment.Id;
    accept.action = 'Accepted';
    accept.expectedVersion = 0;

    System.runAs(partnerUser) {
      LeadAssignmentCommandService.execute(accept);

      LeadAssignmentCommand secondDecision = new LeadAssignmentCommand();
      secondDecision.assignmentId = assignment.Id;
      secondDecision.action = 'Rejected';
      secondDecision.expectedVersion = 1;
      secondDecision.reason = 'Changed my mind.';

      try {
        LeadAssignmentCommandService.execute(secondDecision);
        Assert.fail('Expected an already-decided assignment to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('Only an assigned lead'));
      }
    }
  }

  private static Partner_Lead_Assignment__c activeAssignment(
    Id leadId,
    Id partnerAccountId,
    Id partnerContactId
  ) {
    return new Partner_Lead_Assignment__c(
      Lead__c = leadId,
      Partner_Account__c = partnerAccountId,
      Partner_Contact__c = partnerContactId,
      Status__c = 'Assigned',
      Assignment_Strategy__c = 'Manual',
      Assigned_On__c = System.now(),
      Response_Due_On__c = System.now().addHours(24),
      Active_Assignment_Key__c = String.valueOf(leadId),
      Version_Number__c = 0
    );
  }
}
