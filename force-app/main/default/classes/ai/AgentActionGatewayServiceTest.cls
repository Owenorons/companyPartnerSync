/*
 * Covers AgentActionGatewayService: propose creates a real
 * AI_Recommendation__c only when an active AI_Action_Policy__mdt allows
 * it, execute re-checks permission at execute time rather than trusting
 * the propose-time check (a user who had authority when proposed but lost
 * it before executing is rejected), an unmapped action key is rejected,
 * and executing a mapped action genuinely calls the real command service
 * - proven by the resulting state change, never a bypass.
 */
@IsTest
private class AgentActionGatewayServiceTest {
  @IsTest
  static void proposeCreatesARealRecommendationOnlyForAnAllowedAction() {
    Fixture fixture = createFixture();

    AI_Recommendation__c recommendation = AgentActionGatewayService.proposeAction(
      'RenewalRiskAdvisor',
      'RequestRenewalReview',
      null,
      'Partner_Renewal__c',
      fixture.renewal.Id,
      fixture.partner.Id,
      'Open Critical risk suggests this renewal needs review.',
      75
    );

    Assert.areEqual('Proposed', recommendation.Status__c);
    Assert.isNotNull(recommendation.Id);

    try {
      AgentActionGatewayService.proposeAction(
        'RenewalRiskAdvisor',
        'NoSuchAction',
        null,
        'Partner_Renewal__c',
        fixture.renewal.Id,
        fixture.partner.Id,
        'An action with no policy row.',
        50
      );
      Assert.fail('Expected an unconfigured action to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not permitted'));
    }
  }

  @IsTest
  static void executeGenuinelyDispatchesToTheRealCommandService() {
    Fixture fixture = createFixture();
    AI_Recommendation__c recommendation = AgentActionGatewayService.proposeAction(
      'RenewalRiskAdvisor',
      'RequestRenewalReview',
      null,
      'Partner_Renewal__c',
      fixture.renewal.Id,
      fixture.partner.Id,
      'Open Critical risk suggests this renewal needs review.',
      75
    );
    User authorizedUser = internalRenewalManager();

    AI_Recommendation__c executed;
    System.runAs(authorizedUser) {
      executed = AgentActionGatewayService.executeAction(
        recommendation.Id,
        'AI-recommended review.'
      );
    }

    Assert.areEqual('Executed', executed.Status__c);
    Assert.areEqual(
      'Review Required',
      [SELECT Status__c FROM Partner_Renewal__c WHERE Id = :fixture.renewal.Id]
      .Status__c,
      'Executing the recommendation must genuinely call RenewalCommandService.requestReview(), never bypass it.'
    );
  }

  @IsTest
  static void executeRejectsAUserWhoseAuthorityWasRevokedSincePropose() {
    Fixture fixture = createFixture();
    AI_Recommendation__c recommendation = AgentActionGatewayService.proposeAction(
      'RenewalRiskAdvisor',
      'RequestRenewalReview',
      null,
      'Partner_Renewal__c',
      fixture.renewal.Id,
      fixture.partner.Id,
      'Open Critical risk suggests this renewal needs review.',
      75
    );
    User unauthorizedUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      unauthorizedUser.Id,
      'PartnerSync_Channel_Manager'
    );
    // Deliberately never grants PartnerSync_Manage_Renewal - simulates
    // authority having been revoked between propose and execute.

    System.runAs(unauthorizedUser) {
      try {
        AgentActionGatewayService.executeAction(recommendation.Id, null);
        Assert.fail(
          'Expected execution without the required permission to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }

    Assert.areEqual(
      'Proposed',
      [
        SELECT Status__c
        FROM AI_Recommendation__c
        WHERE Id = :recommendation.Id
      ]
      .Status__c,
      'A rejected execution must never leave the recommendation Executed.'
    );
  }

  private static User internalRenewalManager() {
    User user = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(user.Id, 'PartnerSync_Channel_Manager');
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Renewal',
      true
    );
    return user;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Gateway Test Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Gateway Test Customer'
    );
    insert new List<Account>{ fixture.partner, customer };

    Customer_Success_Engagement__c engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Healthy',
      Version_Number__c = 0
    );
    insert engagement;

    fixture.renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = engagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Partner Confirmed',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert fixture.renewal;

    return fixture;
  }

  private class Fixture {
    Account partner;
    Partner_Renewal__c renewal;
  }
}
