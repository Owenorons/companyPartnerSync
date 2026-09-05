@IsTest
private class CoverageHardeningTest {
  @IsTest
  static void partnerComplianceDtoCarriesPortfolioEvidence() {
    PartnerComplianceItemDTO item = new PartnerComplianceItemDTO();
    item.recordId = UserInfo.getUserId();
    item.onboardingId = UserInfo.getUserId();
    item.category = 'Document';
    item.documentType = 'Insurance';
    item.status = 'Open';
    item.severity = 'High';
    item.dueOn = Date.today();
    item.message = 'Evidence required';
    Assert.areEqual('Document', item.category);
    Assert.areEqual('Evidence required', item.message);
  }

  @IsTest
  static void coversSmallDtosConstantsAndDisabledProvider() {
    Account customer = new Account(Name = 'Customer');
    Account partner = new Account(Name = 'Partner');
    insert new List<Account>{ customer, partner };

    CustomerRevenueDTO revenue = new CustomerRevenueDTO();
    revenue.customerAccountId = customer.Id;
    revenue.customerName = customer.Name;
    revenue.partnerAccountId = partner.Id;
    revenue.partnerName = partner.Name;
    revenue.revenue = 1250;
    revenue.opportunityCount = 2;
    Assert.areEqual(customer.Id, revenue.customerAccountId);
    Assert.areEqual('Customer', revenue.customerName);
    Assert.areEqual(partner.Id, revenue.partnerAccountId);
    Assert.areEqual('Partner', revenue.partnerName);
    Assert.areEqual(1250, revenue.revenue);
    Assert.areEqual(2, revenue.opportunityCount);

    AIInsightRequestDTO insight = new AIInsightRequestDTO();
    insight.partnerAccountId = partner.Id;
    insight.relatedObject = 'Account';
    insight.relatedRecordId = partner.Id;
    insight.insightType = 'Health';
    insight.contextData = new Map<String, Object>{ 'source' => 'test' };
    Assert.areEqual(partner.Id, insight.partnerAccountId);
    Assert.areEqual('Account', insight.relatedObject);
    Assert.areEqual(partner.Id, insight.relatedRecordId);
    Assert.areEqual('Health', insight.insightType);
    Assert.areEqual('test', insight.contextData.get('source'));

    LeadAssignmentRequestDTO assignment = new LeadAssignmentRequestDTO();
    assignment.leadId = partner.Id;
    assignment.partnerAccountId = partner.Id;
    assignment.partnerContactId = partner.Id;
    assignment.customerAccountId = customer.Id;
    assignment.slaHoursOverride = 12;
    assignment.notes = 'Priority';
    Assert.areEqual(partner.Id, assignment.leadId);
    Assert.areEqual(partner.Id, assignment.partnerAccountId);
    Assert.areEqual(partner.Id, assignment.partnerContactId);
    Assert.areEqual(customer.Id, assignment.customerAccountId);
    Assert.areEqual(12, assignment.slaHoursOverride);
    Assert.areEqual('Priority', assignment.notes);

    DealReviewDecisionDTO review = new DealReviewDecisionDTO();
    review.dealId = partner.Id;
    review.decision = 'Approved';
    review.approvalNotes = 'Approved';
    review.rejectionReason = 'None';
    review.conflictResolutionNotes = 'Resolved';
    review.protectionExtensionDays = 30;
    Assert.areEqual(partner.Id, review.dealId);
    Assert.areEqual('Approved', review.decision);
    Assert.areEqual('Approved', review.approvalNotes);
    Assert.areEqual('None', review.rejectionReason);
    Assert.areEqual('Resolved', review.conflictResolutionNotes);
    Assert.areEqual(30, review.protectionExtensionDays);

    LeadDecisionRequestDTO decision = new LeadDecisionRequestDTO();
    decision.leadId = partner.Id;
    decision.decision = 'Accepted';
    decision.notes = 'Qualified';
    Assert.areEqual(partner.Id, decision.leadId);
    Assert.areEqual('Accepted', decision.decision);
    Assert.areEqual('Qualified', decision.notes);

    Assert.areEqual(
      'Deal Registration',
      DealLifecycleConstants.AGGREGATE_REGISTRATION
    );
    Assert.areEqual(
      'Registration',
      DealLifecycleConstants.DIMENSION_REGISTRATION
    );
    Assert.areEqual('Completed', DealLifecycleConstants.OUTCOME_COMPLETED);
    Assert.areEqual(
      'Command In Progress',
      DealLifecycleConstants.OUTCOME_COMMAND_IN_PROGRESS
    );
    Assert.areEqual(
      'Version Conflict',
      DealLifecycleConstants.OUTCOME_VERSION_CONFLICT
    );

    AIProviderResponseDTO disabled = new DisabledAIProvider()
      .generate(new AIProviderRequestDTO());
    Assert.isFalse(disabled.success);
    Assert.areEqual('Disabled', disabled.providerName);
    Assert.areEqual('AI provider disabled', disabled.errorMessage);
  }

  @IsTest
  static void coversTenantConfigurationDefaultsAndValues() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(
        Edition__c = 'Enterprise',
        Enable_Onboarding__c = true,
        Enable_Deals__c = true,
        Enable_Leads__c = true,
        Enable_MDF__c = true,
        Enable_Content__c = true,
        Enable_Analytics__c = true,
        Enable_AI__c = true,
        Deal_Expiry_Days__c = 45,
        Max_Open_Deals_Per_Partner__c = 20,
        Lead_SLA_Hours__c = 24
      )
    );
    Assert.areEqual('Enterprise', TenantConfigService.getEdition());
    Assert.isTrue(TenantConfigService.isOnboardingEnabled());
    Assert.isTrue(TenantConfigService.isDealsEnabled());
    Assert.isTrue(TenantConfigService.isLeadsEnabled());
    Assert.isTrue(TenantConfigService.isMdfEnabled());
    Assert.isTrue(TenantConfigService.isContentEnabled());
    Assert.isTrue(TenantConfigService.isAnalyticsEnabled());
    Assert.isTrue(TenantConfigService.isAiEnabled());
    Assert.areEqual(45, TenantConfigService.getDealExpiryDays());
    Assert.areEqual(20, TenantConfigService.getMaxOpenDealsPerPartner());
    Assert.areEqual(24, TenantConfigService.getLeadSlaHours());

    TenantConfigService.setConfigForTest(new Tenant_Config__mdt());
    Assert.isFalse(TenantConfigService.isAiEnabled());
    Assert.areEqual(30, TenantConfigService.getDealExpiryDays());
    Assert.isNull(TenantConfigService.getMaxOpenDealsPerPartner());
    Assert.areEqual(48, TenantConfigService.getLeadSlaHours());
    TenantConfigService.clearCacheForTest();
  }

  @IsTest
  static void coversSecurityHelpersAndEmptyRecipientResolution() {
    SecurityUtil.assertReadable(Account.SObjectType);
    SecurityUtil.assertCreateable(Account.SObjectType);
    SecurityUtil.assertUpdateable(Account.SObjectType);
    SecurityUtil.assertDeleteable(Account.SObjectType);
    SecurityUtil.assertFieldReadable(Account.SObjectType, 'Name');
    SecurityUtil.assertFieldCreateable(Account.SObjectType, 'Name');
    SecurityUtil.assertFieldUpdateable(Account.SObjectType, 'Name');

    Assert.areEqual(0, SecurityUtil.stripForCreate(null).size());
    Assert.areEqual(0, SecurityUtil.stripForUpdate(new List<SObject>()).size());
    Assert.areEqual(0, SecurityUtil.stripForRead(null).size());
    List<SObject> records = new List<SObject>{ new Account(Name = 'Safe') };
    Assert.areEqual(1, SecurityUtil.stripForCreate(records).size());
    Assert.areEqual(1, SecurityUtil.stripForUpdate(records).size());
    Assert.areEqual(1, SecurityUtil.stripForRead(records).size());

    assertInvalidField('read');
    assertInvalidField('create');
    assertInvalidField('update');
    Assert.areEqual(
      0,
      NotificationRecipientResolver.resolveByPartnerAccount(null).size()
    );
    Assert.areEqual(
      0,
      NotificationRecipientResolver.resolveByPartnerAccount(new Set<Id>())
        .size()
    );
  }

  @IsTest
  static void coversCompactDtosLoggingAndPermissionFallbacks() {
    LeadConversionRequestDTO conversion = new LeadConversionRequestDTO();
    conversion.leadId = UserInfo.getUserId();
    conversion.opportunityName = 'Converted Opportunity';
    conversion.estimatedValue = 1000;
    conversion.estimatedCloseDate = Date.today();
    conversion.stageName = 'Qualification';
    conversion.notes = 'Conversion notes';
    Assert.areEqual('Conversion notes', conversion.notes);

    MDFRequestDTO mdf = new MDFRequestDTO();
    mdf.requestType = 'Webinar';
    mdf.campaignName = 'Campaign';
    mdf.campaignDescription = 'Description';
    mdf.requestedAmount = 500;
    mdf.startDate = Date.today();
    mdf.endDate = Date.today().addDays(1);
    mdf.relatedDealId = UserInfo.getUserId();
    mdf.roiTarget = 2;
    Assert.areEqual(2, mdf.roiTarget);

    LoggingService.info('Coverage', 'Info');
    LoggingService.warn('Coverage', 'Warning');
    LoggingService.error('Coverage', 'No exception', null);
    LoggingService.error(
      'Coverage',
      'With exception',
      new CoverageException('expected')
    );

    Assert.isTrue(DealLifecyclePermissionService.hasPermission(null));
    Assert.isFalse(
      DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Nonexistent_Test_Permission'
      )
    );
  }

  private class CoverageException extends Exception {
  }

  @IsTest
  static void securityHelpersRejectUnpermittedPackageData() {
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      assertObjectDenied('read');
      assertObjectDenied('create');
      assertObjectDenied('update');
      assertObjectDenied('delete');
      assertFieldDenied('read');
      assertFieldDenied('create');
      assertFieldDenied('update');
    }
  }

  private static void assertObjectDenied(String operation) {
    try {
      if (operation == 'read') {
        SecurityUtil.assertReadable(Partner_Application__c.SObjectType);
      } else if (operation == 'create') {
        SecurityUtil.assertCreateable(Partner_Application__c.SObjectType);
      } else if (operation == 'update') {
        SecurityUtil.assertUpdateable(Partner_Application__c.SObjectType);
      } else {
        SecurityUtil.assertDeleteable(Partner_Application__c.SObjectType);
      }
      Assert.fail('Expected object access to be denied.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isNotNull(expected);
    }
  }

  private static void assertFieldDenied(String operation) {
    try {
      if (operation == 'read') {
        SecurityUtil.assertFieldReadable(
          Partner_Application__c.SObjectType,
          'Status__c'
        );
      } else if (operation == 'create') {
        SecurityUtil.assertFieldCreateable(
          Partner_Application__c.SObjectType,
          'Status__c'
        );
      } else {
        SecurityUtil.assertFieldUpdateable(
          Partner_Application__c.SObjectType,
          'Status__c'
        );
      }
      Assert.fail('Expected field access to be denied.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isNotNull(expected);
    }
  }

  private static void assertInvalidField(String operation) {
    try {
      if (operation == 'read') {
        SecurityUtil.assertFieldReadable(Account.SObjectType, 'NotAField');
      } else if (operation == 'create') {
        SecurityUtil.assertFieldCreateable(Account.SObjectType, 'NotAField');
      } else {
        SecurityUtil.assertFieldUpdateable(Account.SObjectType, 'NotAField');
      }
      Assert.fail('Expected invalid field rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('Invalid field'));
    }
  }

  @IsTest
  static void genericResponseEnvelopeMaintainsSuccessAndFailureContracts() {
    Map<String, Object> payload = new Map<String, Object>{ 'count' => 3 };
    PartnerSyncResponseDTO success = PartnerSyncResponseDTO.ok(
      'Completed',
      payload
    );
    Assert.isTrue(success.success);
    Assert.areEqual('Completed', success.message);
    Assert.areEqual(payload, success.data);
    Assert.areEqual(0, success.errors.size());

    PartnerSyncResponseDTO failure = PartnerSyncResponseDTO.fail('Rejected');
    Assert.isFalse(failure.success);
    Assert.areEqual('Rejected', failure.message);
    Assert.areEqual(new List<String>{ 'Rejected' }, failure.errors);
  }

  @IsTest
  static void navigationPickListReturnsBuilderValues() {
    NavigationPickList source = new NavigationPickList();
    Assert.isNotNull(source.getDefaultValue());
    Assert.isNotNull(source.getValues());
  }
}
