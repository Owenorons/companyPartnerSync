@IsTest
private class PartnerPermissionServiceTest {
  @IsTest
  static void administratorHasEveryBusinessCapability() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      adminUser.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(adminUser) {
      Assert.isTrue(PartnerPermissionService.canReviewDeals());
      Assert.isTrue(PartnerPermissionService.canViewAllDeals());
      Assert.isTrue(PartnerPermissionService.canApproveDeal());
      Assert.isTrue(PartnerPermissionService.canRejectDeal());
      Assert.isTrue(PartnerPermissionService.canResolveDealConflict());
      Assert.isTrue(PartnerPermissionService.canViewAllMdf());
      Assert.isTrue(PartnerPermissionService.canApproveMdf());
      Assert.isTrue(PartnerPermissionService.canRejectMdf());
      Assert.isTrue(PartnerPermissionService.canOverrideMdfBudget());
      Assert.isTrue(PartnerPermissionService.canAssignLeads());
      Assert.isTrue(PartnerPermissionService.canAccessInternalAnalytics());
      Assert.isTrue(PartnerPermissionService.canViewExecutiveAnalytics());
      Assert.isTrue(PartnerPermissionService.canExportExecutiveReports());
      Assert.isTrue(PartnerPermissionService.canConfigureAI());
      Assert.isTrue(PartnerPermissionService.canManageContent());
      Assert.isTrue(PartnerPermissionService.canApprovePartnerApplications());
      Assert.isTrue(PartnerPermissionService.canManageRecordShares());
    }
  }

  @IsTest
  static void administratorDealAndMdfAssertionsSucceed() {
    User adminUser = administrator();
    System.runAs(adminUser) {
      PartnerPermissionService.assertCanReviewDeals();
      PartnerPermissionService.assertCanViewAllDeals();
      PartnerPermissionService.assertCanApproveDeal();
      PartnerPermissionService.assertCanRejectDeal();
      PartnerPermissionService.assertCanResolveDealConflict();
      PartnerPermissionService.assertCanViewAllMdf();
      PartnerPermissionService.assertCanApproveMdf();
      PartnerPermissionService.assertCanRejectMdf();
    }
  }

  @IsTest
  static void administratorOperationalAssertionsSucceed() {
    User adminUser = administrator();
    System.runAs(adminUser) {
      PartnerPermissionService.assertCanOverrideMdfBudget();
      PartnerPermissionService.assertCanAssignLeads();
      PartnerPermissionService.assertCanAccessInternalAnalytics();
      PartnerPermissionService.assertCanViewExecutiveAnalytics();
      PartnerPermissionService.assertCanExportExecutiveReports();
    }
  }

  @IsTest
  static void administratorConfigurationAssertionsSucceed() {
    User adminUser = administrator();
    System.runAs(adminUser) {
      PartnerPermissionService.assertCanConfigureAI();
      PartnerPermissionService.assertCanManageContent();
      PartnerPermissionService.assertCanApprovePartnerApplications();
      PartnerPermissionService.assertCanManageRecordShares();
    }
  }

  @IsTest
  static void plainInternalUserIsDeniedEveryAssertion() {
    User plainUser = TestUserFactory.createInternalUser();
    System.runAs(plainUser) {
      for (Integer operation = 0; operation < 17; operation++) {
        assertDenied(operation);
      }
    }
  }

  private static void assertDenied(Integer operation) {
    try {
      if (operation == 0)
        PartnerPermissionService.assertCanReviewDeals();
      else if (operation == 1)
        PartnerPermissionService.assertCanViewAllDeals();
      else if (operation == 2)
        PartnerPermissionService.assertCanApproveDeal();
      else if (operation == 3)
        PartnerPermissionService.assertCanRejectDeal();
      else if (operation == 4)
        PartnerPermissionService.assertCanResolveDealConflict();
      else if (operation == 5)
        PartnerPermissionService.assertCanViewAllMdf();
      else if (operation == 6)
        PartnerPermissionService.assertCanApproveMdf();
      else if (operation == 7)
        PartnerPermissionService.assertCanRejectMdf();
      else if (operation == 8)
        PartnerPermissionService.assertCanOverrideMdfBudget();
      else if (operation == 9)
        PartnerPermissionService.assertCanAssignLeads();
      else if (operation == 10)
        PartnerPermissionService.assertCanAccessInternalAnalytics();
      else if (operation == 11)
        PartnerPermissionService.assertCanViewExecutiveAnalytics();
      else if (operation == 12)
        PartnerPermissionService.assertCanExportExecutiveReports();
      else if (operation == 13)
        PartnerPermissionService.assertCanConfigureAI();
      else if (operation == 14)
        PartnerPermissionService.assertCanManageContent();
      else if (operation == 15)
        PartnerPermissionService.assertCanApprovePartnerApplications();
      else
        PartnerPermissionService.assertCanManageRecordShares();
      Assert.fail('Expected permission denial for operation ' + operation);
    } catch (PartnerSyncHandledException expected) {
      Assert.isNotNull(expected);
    }
  }

  private static User administrator() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      adminUser.Id,
      'PSG_Internal_Administrator'
    );
    return adminUser;
  }
}
