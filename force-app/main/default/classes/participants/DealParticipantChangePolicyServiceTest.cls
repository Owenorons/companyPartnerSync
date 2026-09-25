/*
 * Covers DealParticipantChangePolicyService against the seeded CMDT
 * policy: adding a protected co-sell participant triggers conflict
 * reanalysis and review/approval reassessment, while a plain participant
 * addition (no protection) does not.
 */
@IsTest
private class DealParticipantChangePolicyServiceTest {
  @IsTest
  static void protectedParticipantAddedTriggersConflictReanalysis() {
    Fixture fixture = createFixture();

    Test.startTest();
    DealParticipantChangePolicyService.evaluate(
      fixture.deal.Id,
      'ProtectedParticipantAdded',
      null
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Conflict_Analysis_Run__c
        WHERE Deal__c = :fixture.deal.Id AND Current__c = TRUE
      ]
    );
  }

  @IsTest
  static void plainParticipantAddedDoesNotTriggerReanalysis() {
    Fixture fixture = createFixture();

    DealParticipantChangePolicyService.evaluate(
      fixture.deal.Id,
      'ParticipantAdded',
      null
    );

    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Deal_Conflict_Analysis_Run__c
        WHERE Deal__c = :fixture.deal.Id
      ]
    );
  }

  @IsTest
  static void protectedParticipantAddedRequiresAProtectionAmendment() {
    Assert.isTrue(
      DealParticipantChangePolicyService.requiresProtectionAmendment(
        'ProtectedParticipantAdded'
      )
    );
    Assert.isFalse(
      DealParticipantChangePolicyService.requiresProtectionAmendment(
        'ParticipantAdded'
      )
    );
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };
    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;
    return fixture;
  }

  private class Fixture {
    Deal_Registration__c deal;
  }
}
