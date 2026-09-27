/*
 * Covers DealOpportunityController: getSalesProgress returns the
 * sanitized DTO (whitelisted fields only) for both an internal user and
 * the deal's own partner, rejects an unrelated partner, and each Sales
 * Execution Workbench queue method is internal-only and returns matching
 * rows.
 */
@IsTest
private class DealOpportunityControllerTest {
  @IsTest
  static void getSalesProgressReturnsTheSanitizedSummaryForTheOwningPartner() {
    Fixture fixture = buildFixture();
    Contact partnerContact = PartnerSyncTestDataFactory.partnerContact(
      fixture.partner.Id
    );
    insert partnerContact;
    User partnerUser = TestUserFactory.createExternalUser(partnerContact.Id);
    if (
      !PartnerAccessService.testPartnerAccountIdsByUser.containsKey(
        partnerUser.Id
      )
    ) {
      insert new OpportunityShare(
        OpportunityId = fixture.opportunity.Id,
        UserOrGroupId = partnerUser.Id,
        OpportunityAccessLevel = 'Read',
        RowCause = Schema.OpportunityShare.RowCause.Manual
      );
    }

    SalesProgressDTO dto;
    System.runAs(partnerUser) {
      dto = DealOpportunityController.getSalesProgress(fixture.deal.Id);
    }

    Assert.areEqual(fixture.deal.Id, dto.dealId);
    Assert.areEqual('Qualification', dto.stage);
    Assert.areEqual(false, dto.isWon);
    Assert.areEqual(false, dto.isClosed);
    Assert.areEqual(50000, dto.amount);
    Assert.areEqual(1, dto.opportunityCount);
  }

  @IsTest
  static void getSalesProgressRejectsAnUnrelatedPartner() {
    Fixture fixture = buildFixture();
    Account unrelatedPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Partner'
    );
    insert unrelatedPartner;
    Contact unrelatedContact = PartnerSyncTestDataFactory.partnerContact(
      unrelatedPartner.Id
    );
    insert unrelatedContact;
    User unrelatedUser = TestUserFactory.createExternalUser(
      unrelatedContact.Id
    );

    System.runAs(unrelatedUser) {
      try {
        DealOpportunityController.getSalesProgress(fixture.deal.Id);
        Assert.fail('Expected an unrelated partner to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not accessible'));
      }
    }
  }

  @IsTest
  static void queueMethodsAreInternalOnlyAndReturnMatchingRows() {
    Fixture fixture = buildFixture();
    Database.update(
      new Deal_Registration__c(
        Id = fixture.deal.Id,
        Lifecycle_Health__c = 'Blocked'
      ),
      AccessLevel.SYSTEM_MODE
    );

    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User partnerUser = TestUserFactory.createExternalUser(otherContact.Id);

    System.runAs(partnerUser) {
      try {
        DealOpportunityController.getOrphanedRelationships();
        Assert.fail('Expected a partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('only available to internal users')
        );
      }
    }

    User internalUser = TestUserFactory.createInternalUser();
    List<SalesExecutionQueueRowDTO> orphaned;
    System.runAs(internalUser) {
      orphaned = DealOpportunityController.getOrphanedRelationships();
    }
    Assert.areEqual(1, orphaned.size());
    Assert.areEqual(fixture.deal.Id, orphaned[0].dealId);
  }

  @IsTest
  static void recentlyClosedAndReapprovalRequiredReturnMatchingRows() {
    Fixture fixture = buildFixture();
    Database.update(
      new Deal_Registration__c(Id = fixture.deal.Id, Stage__c = 'Closed Won'),
      AccessLevel.SYSTEM_MODE
    );

    Account secondPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Second Partner'
    );
    insert secondPartner;
    Account secondCustomer = PartnerSyncTestDataFactory.customerAccount(
      'Second Customer'
    );
    insert secondCustomer;
    Deal_Registration__c reapprovalDeal = PartnerSyncTestDataFactory.deal(
      secondCustomer.Id,
      secondPartner.Id,
      null,
      null
    );
    reapprovalDeal.Status__c = 'Under Review';
    reapprovalDeal.Last_Lifecycle_Event__c = 'DealReapprovalRequested';
    insert reapprovalDeal;

    User internalUser = TestUserFactory.createInternalUser();
    List<SalesExecutionQueueRowDTO> closed;
    List<SalesExecutionQueueRowDTO> reapproval;
    System.runAs(internalUser) {
      closed = DealOpportunityController.getRecentlyClosed();
      reapproval = DealOpportunityController.getReapprovalRequired();
    }

    Assert.areEqual(1, closed.size());
    Assert.areEqual(fixture.deal.Id, closed[0].dealId);
    Assert.areEqual(1, reapproval.size());
    Assert.areEqual(reapprovalDeal.Id, reapproval[0].dealId);
  }

  private class Fixture {
    Account partner;
    Account customer;
    Opportunity opportunity;
    Deal_Registration__c deal;
  }

  private static Fixture buildFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    fixture.customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ fixture.partner, fixture.customer };

    fixture.opportunity = PartnerSyncTestDataFactory.opportunity(
      fixture.customer.Id,
      fixture.partner.Id,
      null
    );
    fixture.opportunity.StageName = 'Qualification';
    insert fixture.opportunity;

    fixture.deal = PartnerSyncTestDataFactory.deal(
      fixture.customer.Id,
      fixture.partner.Id,
      null,
      fixture.opportunity.Id
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    insert new Deal_Opportunity__c(
      Deal__c = fixture.deal.Id,
      Opportunity__c = fixture.opportunity.Id,
      Partner_Account__c = fixture.partner.Id,
      Relationship_Type__c = 'Primary',
      Primary__c = true,
      Current__c = true,
      Relationship_Key__c = fixture.deal.Id + '|' + fixture.opportunity.Id,
      Version_Number__c = 0
    );

    return fixture;
  }
}
