/*
 * Coverage for PartnerPermissionService's role-based gates: proves each
 * business permission set grants exactly the capabilities it's meant to
 * (e.g. an executive can view but not decide) and nothing more.
 */
@IsTest
private class PartnerPermissionServiceTest {
  @IsTest
  static void executiveCanViewButNotDecideDealsOrMdf() {
    User executiveUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      System.assertEquals(
        true,
        PartnerPermissionService.canViewAllDeals(),
        'Executive should see the deal review queue.'
      );
      System.assertEquals(
        true,
        PartnerPermissionService.canViewAllMdf(),
        'Executive should see the MDF review queue.'
      );

      System.assertEquals(false, PartnerPermissionService.canApproveDeal());
      System.assertEquals(false, PartnerPermissionService.canRejectDeal());
      System.assertEquals(
        false,
        PartnerPermissionService.canResolveDealConflict()
      );
      System.assertEquals(false, PartnerPermissionService.canApproveMdf());
      System.assertEquals(false, PartnerPermissionService.canRejectMdf());
      System.assertEquals(
        false,
        PartnerPermissionService.canOverrideMdfBudget()
      );
    }
  }

  @IsTest
  static void executiveCanViewAndExportAnalyticsButNotConfigureAi() {
    User executiveUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      System.assertEquals(
        true,
        PartnerPermissionService.canViewExecutiveAnalytics()
      );
      System.assertEquals(
        true,
        PartnerPermissionService.canExportExecutiveReports()
      );
      System.assertEquals(false, PartnerPermissionService.canConfigureAI());
    }
  }

  @IsTest
  static void channelManagerCanDecideDealsButNotMdfWithoutReviewerPermission() {
    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      System.assertEquals(true, PartnerPermissionService.canApproveDeal());
      System.assertEquals(true, PartnerPermissionService.canRejectDeal());
      System.assertEquals(
        true,
        PartnerPermissionService.canResolveDealConflict()
      );

      System.assertEquals(
        true,
        PartnerPermissionService.canViewAllMdf(),
        'Channel Manager can view MDF summaries without the reviewer permission set.'
      );
      System.assertEquals(
        false,
        PartnerPermissionService.canApproveMdf(),
        'Channel Manager needs PartnerSync_MDF_Reviewer to approve MDF.'
      );

      System.assertEquals(
        false,
        PartnerPermissionService.canViewExecutiveAnalytics(),
        'Executive analytics is optional for Channel Manager, not baked in.'
      );
    }
  }

  @IsTest
  static void mdfReviewerCanApproveAndRejectMdf() {
    User mdfReviewer = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      mdfReviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );

    System.runAs(mdfReviewer) {
      System.assertEquals(true, PartnerPermissionService.canApproveMdf());
      System.assertEquals(true, PartnerPermissionService.canRejectMdf());
      System.assertEquals(
        true,
        PartnerPermissionService.canOverrideMdfBudget()
      );

      System.assertEquals(
        false,
        PartnerPermissionService.canApproveDeal(),
        'MDF Reviewer alone should not grant deal approval.'
      );
    }
  }

  @IsTest
  static void internalAdminNeedsAiAdminPermissionSetToConfigureAi() {
    User internalAdmin = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(internalAdmin) {
      System.assertEquals(
        false,
        PartnerPermissionService.canConfigureAI(),
        'Internal Admin alone should not grant AI configuration rights.'
      );
    }

    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_AI_Admin'
    );

    System.runAs(internalAdmin) {
      System.assertEquals(true, PartnerPermissionService.canConfigureAI());
    }
  }

  @IsTest
  static void plainInternalUserCanDoNothingGranular() {
    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      System.assertEquals(false, PartnerPermissionService.canViewAllDeals());
      System.assertEquals(false, PartnerPermissionService.canApproveDeal());
      System.assertEquals(false, PartnerPermissionService.canViewAllMdf());
      System.assertEquals(false, PartnerPermissionService.canApproveMdf());
      System.assertEquals(
        false,
        PartnerPermissionService.canViewExecutiveAnalytics()
      );
      System.assertEquals(false, PartnerPermissionService.canConfigureAI());
    }
  }

  @IsTest
  static void assertMethodsThrowWhenCapabilityIsMissing() {
    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Boolean threw = false;

      try {
        PartnerPermissionService.assertCanApproveDeal();
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'assertCanApproveDeal should throw when the custom permission is missing.'
      );
    }
  }
}
