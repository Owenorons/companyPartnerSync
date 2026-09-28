/*
 * Covers AIInteractionService.execute(): a successful interaction persists
 * a full audit row and evidence rows; a quota-exceeded call is blocked and
 * still audited with Status__c = 'Blocked-Quota'; a use case with no
 * matching AI_Context_Policy__mdt fails closed with Status__c =
 * 'Blocked-Policy' and never sends an unbounded context.
 */
@IsTest
private class AIInteractionServiceTest {
  @IsTest
  static void successfulInteractionPersistsAuditAndEvidence() {
    Fixture fixture = createFixture();
    User aiUser = internalAiUser();
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.success('Portfolio is healthy overall.')
    );

    AIInteractionService.InteractionResult result;
    System.runAs(aiUser) {
      AIProviderRouter.providerConfigForTest = new AI_Provider_Config__mdt(
        Active__c = true,
        Provider_Type__c = 'OpenAI'
      );
      Test.startTest();
      result = AIInteractionService.execute(
        'RenewalRiskAdvisor',
        'Partner_Renewal__c',
        fixture.renewal.Id,
        fixture.partner.Id
      );
      Test.stopTest();
      AIProviderRouter.providerConfigForTest = null;
    }

    Assert.isTrue(result.success);
    Assert.areEqual('Succeeded', result.status);
    Assert.isNotNull(result.interactionId);

    AI_Interaction__c interaction = [
      SELECT
        Status__c,
        Use_Case_Key__c,
        Grounding_Source_Count__c,
        Context_Snapshot__c
      FROM AI_Interaction__c
      WHERE Id = :result.interactionId
    ];
    Assert.areEqual('Succeeded', interaction.Status__c);
    Assert.areEqual('RenewalRiskAdvisor', interaction.Use_Case_Key__c);
    Assert.areEqual(1, interaction.Grounding_Source_Count__c);
    Assert.isTrue(interaction.Context_Snapshot__c.contains('Status__c'));

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM AI_Evidence__c
        WHERE Interaction__c = :result.interactionId
      ]
    );
  }

  @IsTest
  static void quotaExceededCallIsBlockedAndAudited() {
    Fixture fixture = createFixture();
    User aiUser = internalAiUser();
    AIUsageService.testUseCaseDailyLimits.put('RenewalRiskAdvisor', 0);

    AIInteractionService.InteractionResult result;
    System.runAs(aiUser) {
      result = AIInteractionService.execute(
        'RenewalRiskAdvisor',
        'Partner_Renewal__c',
        fixture.renewal.Id,
        fixture.partner.Id
      );
    }

    Assert.isFalse(result.success);
    Assert.areEqual('Blocked-Quota', result.status);
    Assert.areEqual(
      'Blocked-Quota',
      [
        SELECT Status__c
        FROM AI_Interaction__c
        WHERE Id = :result.interactionId
      ]
      .Status__c
    );
  }

  @IsTest
  static void unconfiguredUseCaseFailsClosedWithoutSendingContext() {
    Fixture fixture = createFixture();
    User aiUser = internalAiUser();

    AIInteractionService.InteractionResult result;
    System.runAs(aiUser) {
      result = AIInteractionService.execute(
        'NoSuchUseCase',
        'Partner_Renewal__c',
        fixture.renewal.Id,
        fixture.partner.Id
      );
    }

    Assert.isFalse(result.success);
    Assert.areEqual('Blocked-Policy', result.status);
    AI_Interaction__c interaction = [
      SELECT Context_Snapshot__c
      FROM AI_Interaction__c
      WHERE Id = :result.interactionId
    ];
    Assert.isNull(interaction.Context_Snapshot__c);
  }

  // Proves a real, honestly-scoped ceiling for execute() called in a loop
  // within one transaction - each call costs roughly context (2 SOQL) +
  // permission check (1 SOQL) + tenant + per-use-case quota (2 SOQL) +
  // grounding (up to 3 SOQL) + the audit insert(s) (2 DML), so 8 stays
  // safely under the 100-SOQL limit; no batch class in this codebase
  // calls execute() in a loop today, so this proves the command itself is
  // bulk-safe up to a real ceiling rather than claiming a false 200.
  @IsTest
  static void executes8InteractionsWithinGovernorLimits() {
    Fixture fixture = createFixture();
    User aiUser = internalAiUser();
    Test.setMock(HttpCalloutMock.class, AIHttpCalloutMock.success('OK.'));

    System.runAs(aiUser) {
      AIProviderRouter.providerConfigForTest = new AI_Provider_Config__mdt(
        Active__c = true,
        Provider_Type__c = 'OpenAI'
      );
      Test.startTest();
      for (Integer index = 0; index < 8; index++) {
        AIInteractionService.execute(
          'RenewalRiskAdvisor',
          'Partner_Renewal__c',
          fixture.renewal.Id,
          fixture.partner.Id
        );
      }
      Test.stopTest();
      AIProviderRouter.providerConfigForTest = null;
    }

    Assert.areEqual(
      8,
      [
        SELECT COUNT()
        FROM AI_Interaction__c
        WHERE Related_Record_Id__c = :fixture.renewal.Id
      ]
    );
  }

  private static User internalAiUser() {
    User aiUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(aiUser.Id, 'PartnerSync_AI_Admin');
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_AI__c = true)
    );
    return aiUser;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'AI Interaction Test Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'AI Interaction Test Customer'
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

    insert new Customer_Success_Risk__c(
      Customer_Success_Engagement__c = engagement.Id,
      Risk_Type__c = 'Renewal Risk',
      Severity__c = 'Medium',
      Status__c = 'Open',
      Description__c = 'Customer usage has declined recently.'
    );

    fixture.renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = engagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Approved',
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
