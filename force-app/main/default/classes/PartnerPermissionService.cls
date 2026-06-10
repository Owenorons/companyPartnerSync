public with sharing class PartnerPermissionService {
  public static Boolean canReviewDeals() {
    return PartnerAccessService.isInternalUser();
  }

  public static Boolean canApproveMdf() {
    return PartnerAccessService.isInternalUser();
  }

  public static Boolean canAssignLeads() {
    return PartnerAccessService.isInternalUser();
  }

  public static Boolean canAccessInternalAnalytics() {
    return PartnerAccessService.isInternalUser();
  }

  public static void assertCanReviewDeals() {
    if (!canReviewDeals()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to review deals.'
      );
    }
  }

  public static void assertCanApproveMdf() {
    if (!canApproveMdf()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to approve MDF.'
      );
    }
  }

  public static void assertCanAssignLeads() {
    if (!canAssignLeads()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to assign leads.'
      );
    }
  }

  public static void assertCanAccessInternalAnalytics() {
    if (!canAccessInternalAnalytics()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to access internal analytics.'
      );
    }
  }
}
