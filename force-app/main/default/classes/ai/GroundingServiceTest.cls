/*
 * Covers GroundingService.findEvidence(): results are bounded by the
 * configured Max_Results__c, only the correct renewal's own customer
 * success engagement's risks are ever returned (never another
 * engagement's), and an unconfigured use case returns no candidates.
 */
@IsTest
private class GroundingServiceTest {
  @IsTest
  static void findsOnlyTheRenewalsOwnEngagementRisksBoundedByMaxResults() {
    Fixture fixture = createFixture();
    for (Integer index = 0; index < 8; index++) {
      insert new Customer_Success_Risk__c(
        Customer_Success_Engagement__c = fixture.engagement.Id,
        Risk_Type__c = 'Adoption Risk',
        Severity__c = 'Medium',
        Status__c = 'Open',
        Description__c = 'Risk number ' + index
      );
    }
    // A risk on an unrelated engagement must never leak into these results.
    insert new Customer_Success_Risk__c(
      Customer_Success_Engagement__c = fixture.otherEngagement.Id,
      Risk_Type__c = 'Commercial Risk',
      Severity__c = 'Critical',
      Status__c = 'Open',
      Description__c = 'Unrelated risk that must not appear.'
    );

    List<GroundingService.Evidence> evidence = GroundingService.findEvidence(
      'RenewalRiskAdvisor',
      'Partner_Renewal__c',
      fixture.renewal.Id
    );

    Assert.areEqual(
      5,
      evidence.size(),
      'Results must be bounded by the configured Max_Results__c (5).'
    );
    for (GroundingService.Evidence row : evidence) {
      Assert.isFalse(
        row.excerpt.contains('Unrelated risk'),
        'Evidence from a different engagement must never appear.'
      );
    }
  }

  @IsTest
  static void resolvedRisksAreExcluded() {
    Fixture fixture = createFixture();
    insert new Customer_Success_Risk__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Risk_Type__c = 'Support Issue',
      Severity__c = 'Low',
      Status__c = 'Resolved',
      Description__c = 'Already resolved.',
      Resolution__c = 'Fixed.'
    );

    List<GroundingService.Evidence> evidence = GroundingService.findEvidence(
      'RenewalRiskAdvisor',
      'Partner_Renewal__c',
      fixture.renewal.Id
    );

    Assert.isTrue(evidence.isEmpty());
  }

  @IsTest
  static void anUnconfiguredUseCaseReturnsNoCandidates() {
    Fixture fixture = createFixture();

    List<GroundingService.Evidence> evidence = GroundingService.findEvidence(
      'NoSuchUseCase',
      'Partner_Renewal__c',
      fixture.renewal.Id
    );

    Assert.isTrue(evidence.isEmpty());
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Grounding Test Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Grounding Test Customer'
    );
    insert new List<Account>{ partner, customer };

    fixture.engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Healthy',
      Version_Number__c = 0
    );
    fixture.otherEngagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Healthy',
      Version_Number__c = 0
    );
    insert new List<Customer_Success_Engagement__c>{
      fixture.engagement,
      fixture.otherEngagement
    };

    fixture.renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Approved',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert fixture.renewal;

    return fixture;
  }

  private class Fixture {
    Customer_Success_Engagement__c engagement;
    Customer_Success_Engagement__c otherEngagement;
    Partner_Renewal__c renewal;
  }
}
