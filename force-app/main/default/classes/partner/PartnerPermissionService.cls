/**
 * Business/role-level authorization: one canX()/assertCanX() pair per
 * capability, each backed by a named list of permission sets and, for
 * higher-stakes actions, an additional Custom Permission check. This is
 * where "who is allowed to do what" is defined; PartnerAccessService and
 * PartnerRecordAccessService consume these rather than checking permission
 * sets directly.
 */
public with sharing class PartnerPermissionService {
  /*
   * Executive visibility != approval authority. PartnerSync_Executive_User is
   * deliberately excluded from every approve/reject/resolve/override list
   * below and only appears on the *_VIEW lists and the executive-analytics
   * custom permissions. Fine-grained actions (approve, reject, resolve,
   * override) are gated by a specific Custom Permission checked via
   * FeatureManagement.checkPermission, not by broad role membership, so an
   * org can grant or withhold a single capability without editing Apex.
   */

  private static final List<String> DEAL_REVIEW_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_Internal_Admin'
  };

  private static final List<String> DEAL_VIEW_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_Internal_Admin',
    'PartnerSync_Executive_User'
  };

  private static final List<String> MDF_APPROVE_PERMISSION_SETS = new List<String>{
    'PartnerSync_MDF_Reviewer',
    'PartnerSync_Internal_Admin'
  };

  private static final List<String> MDF_VIEW_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_MDF_Reviewer',
    'PartnerSync_Internal_Admin',
    'PartnerSync_Executive_User'
  };

  private static final List<String> LEAD_ASSIGN_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_Internal_Admin'
  };

  private static final List<String> INTERNAL_ANALYTICS_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_Internal_Admin',
    'PartnerSync_Executive_User'
  };

  private static final List<String> PARTNER_APPLICATION_APPROVE_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_Internal_Admin'
  };

  /*
   * Deliberately its own list rather than reusing DEAL_REVIEW_PERMISSION_SETS:
   * granting/revoking a Partner_Record_Share__c (co-sell, escalation, or
   * conflict-review access) isn't a deal-review action even though today's
   * membership happens to match — see PartnerShareService.
   */
  private static final List<String> RECORD_SHARE_MANAGE_PERMISSION_SETS = new List<String>{
    'PartnerSync_Channel_Manager',
    'PartnerSync_Internal_Admin'
  };

  /**
   * Checks whether the running internal user can review deal registrations.
   *
   * @return True if the user holds one of the deal-review permission sets.
   */
  public static Boolean canReviewDeals() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(DEAL_REVIEW_PERMISSION_SETS);
  }

  /**
   * Checks whether the running internal user can view all deal
   * registrations, not just their own.
   *
   * @return True if the user holds one of the deal-view permission sets.
   */
  public static Boolean canViewAllDeals() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(DEAL_VIEW_PERMISSION_SETS);
  }

  /**
   * Checks whether the running user can approve deal registrations.
   *
   * @return True if the user can review deals and holds the
   * PartnerSync_Approve_Deal custom permission.
   */
  public static Boolean canApproveDeal() {
    return canReviewDeals() &&
      PermissionService.hasCustomPermission('PartnerSync_Approve_Deal');
  }

  /**
   * Checks whether the running user can reject deal registrations.
   *
   * @return True if the user can review deals and holds the
   * PartnerSync_Reject_Deal custom permission.
   */
  public static Boolean canRejectDeal() {
    return canReviewDeals() &&
      PermissionService.hasCustomPermission('PartnerSync_Reject_Deal');
  }

  /**
   * Checks whether the running user can resolve a deal registration
   * conflict.
   *
   * @return True if the user can review deals and holds the
   * PartnerSync_Resolve_Deal_Conflict custom permission.
   */
  public static Boolean canResolveDealConflict() {
    return canReviewDeals() &&
      PermissionService.hasCustomPermission(
        'PartnerSync_Resolve_Deal_Conflict'
      );
  }

  /**
   * Checks whether the running internal user can view all MDF requests.
   *
   * @return True if the user holds one of the MDF-view permission sets.
   */
  public static Boolean canViewAllMdf() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(MDF_VIEW_PERMISSION_SETS);
  }

  /**
   * Checks whether the running user can approve MDF requests.
   *
   * @return True if the user holds one of the MDF-approve permission sets
   * and the PartnerSync_Approve_MDF custom permission.
   */
  public static Boolean canApproveMdf() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(MDF_APPROVE_PERMISSION_SETS) &&
      PermissionService.hasCustomPermission('PartnerSync_Approve_MDF');
  }

  /**
   * Checks whether the running user can reject MDF requests.
   *
   * @return True if the user holds one of the MDF-approve permission sets
   * and the PartnerSync_Reject_MDF custom permission.
   */
  public static Boolean canRejectMdf() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(MDF_APPROVE_PERMISSION_SETS) &&
      PermissionService.hasCustomPermission('PartnerSync_Reject_MDF');
  }

  /**
   * Checks whether the running user can override the MDF budget cap.
   *
   * @return True if the user holds one of the MDF-approve permission sets
   * and the PartnerSync_Override_MDF_Budget custom permission.
   */
  public static Boolean canOverrideMdfBudget() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(MDF_APPROVE_PERMISSION_SETS) &&
      PermissionService.hasCustomPermission('PartnerSync_Override_MDF_Budget');
  }

  /**
   * Checks whether the running internal user can assign leads.
   *
   * @return True if the user holds one of the lead-assign permission sets.
   */
  public static Boolean canAssignLeads() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(LEAD_ASSIGN_PERMISSION_SETS);
  }

  /**
   * Checks whether the running internal user can access internal
   * analytics.
   *
   * @return True if the user holds one of the internal-analytics
   * permission sets.
   */
  public static Boolean canAccessInternalAnalytics() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(INTERNAL_ANALYTICS_PERMISSION_SETS);
  }

  /**
   * Checks whether the running internal user can view executive analytics.
   *
   * @return True if the user holds the
   * PartnerSync_View_Executive_Analytics custom permission.
   */
  public static Boolean canViewExecutiveAnalytics() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasCustomPermission(
        'PartnerSync_View_Executive_Analytics'
      );
  }

  /**
   * Checks whether the running internal user can export executive reports.
   *
   * @return True if the user holds the
   * PartnerSync_Export_Executive_Reports custom permission.
   */
  public static Boolean canExportExecutiveReports() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasCustomPermission(
        'PartnerSync_Export_Executive_Reports'
      );
  }

  /**
   * Checks whether the running internal user can configure AI providers.
   *
   * @return True if the user holds the PartnerSync_AI_Admin permission
   * set.
   */
  public static Boolean canConfigureAI() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasPermissionSet('PartnerSync_AI_Admin');
  }

  /**
   * Checks whether the running internal user can generate AI insights.
   *
   * @return True if the user holds the
   * PartnerSync_Generate_AI_Insights custom permission.
   */
  public static Boolean canGenerateAIInsights() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasCustomPermission('PartnerSync_Generate_AI_Insights');
  }

  /**
   * Checks whether the running internal user can review AI insights.
   *
   * @return True if the user holds the PartnerSync_Review_AI_Insights
   * custom permission.
   */
  public static Boolean canReviewAIInsights() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasCustomPermission('PartnerSync_Review_AI_Insights');
  }

  /**
   * Checks whether the running internal user can manage content.
   *
   * @return True if the user holds the PartnerSync_Content_Admin
   * permission set.
   */
  public static Boolean canManageContent() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasPermissionSet('PartnerSync_Content_Admin');
  }

  /**
   * Checks whether the running internal user can approve partner
   * applications.
   *
   * @return True if the user holds one of the partner-application-approve
   * permission sets.
   */
  public static Boolean canApprovePartnerApplications() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(
        PARTNER_APPLICATION_APPROVE_PERMISSION_SETS
      );
  }

  /**
   * Checks whether the running internal user can manage partner record
   * shares.
   *
   * @return True if the user holds one of the record-share-manage
   * permission sets.
   */
  public static Boolean canManageRecordShares() {
    return PartnerAccessService.isInternalUser() &&
      PermissionService.hasAnyPermissionSet(
        RECORD_SHARE_MANAGE_PERMISSION_SETS
      );
  }

  /**
   * Throws a handled exception unless the running user can review deals.
   */
  public static void assertCanReviewDeals() {
    if (!canReviewDeals()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to review deals.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can view all deal
   * registrations.
   */
  public static void assertCanViewAllDeals() {
    if (!canViewAllDeals()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to view deal registrations.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can approve deal
   * registrations.
   */
  public static void assertCanApproveDeal() {
    if (!canApproveDeal()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to approve deal registrations.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can reject deal
   * registrations.
   */
  public static void assertCanRejectDeal() {
    if (!canRejectDeal()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to reject deal registrations.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can resolve a deal
   * registration conflict.
   */
  public static void assertCanResolveDealConflict() {
    if (!canResolveDealConflict()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to resolve deal conflicts.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can view all MDF
   * requests.
   */
  public static void assertCanViewAllMdf() {
    if (!canViewAllMdf()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to view MDF requests.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can approve MDF
   * requests.
   */
  public static void assertCanApproveMdf() {
    if (!canApproveMdf()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to approve MDF requests.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can reject MDF
   * requests.
   */
  public static void assertCanRejectMdf() {
    if (!canRejectMdf()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to reject MDF requests.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can override the
   * MDF budget cap.
   */
  public static void assertCanOverrideMdfBudget() {
    if (!canOverrideMdfBudget()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to override the MDF budget cap.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can assign leads.
   */
  public static void assertCanAssignLeads() {
    if (!canAssignLeads()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to assign leads.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can access internal
   * analytics.
   */
  public static void assertCanAccessInternalAnalytics() {
    if (!canAccessInternalAnalytics()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to access internal analytics.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can view executive
   * analytics.
   */
  public static void assertCanViewExecutiveAnalytics() {
    if (!canViewExecutiveAnalytics()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to view executive analytics.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can export
   * executive reports.
   */
  public static void assertCanExportExecutiveReports() {
    if (!canExportExecutiveReports()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to export executive reports.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can configure AI
   * providers.
   */
  public static void assertCanConfigureAI() {
    if (!canConfigureAI()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to configure AI providers.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can generate AI
   * insights.
   */
  public static void assertCanGenerateAIInsights() {
    if (!canGenerateAIInsights()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to generate AI insights.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can review AI
   * insights.
   */
  public static void assertCanReviewAIInsights() {
    if (!canReviewAIInsights()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to review AI insights.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can manage
   * content.
   */
  public static void assertCanManageContent() {
    if (!canManageContent()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to manage content.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can approve partner
   * applications.
   */
  public static void assertCanApprovePartnerApplications() {
    if (!canApprovePartnerApplications()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to approve partner applications.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user can manage partner
   * record shares.
   */
  public static void assertCanManageRecordShares() {
    if (!canManageRecordShares()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to manage partner record shares.'
      );
    }
  }
}
