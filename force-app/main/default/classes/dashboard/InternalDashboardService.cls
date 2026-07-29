/*
 * Assembles the internal-user dashboard: org-wide review-queue counts and
 * unread notifications for the signed-in employee. Mirrors
 * PartnerDashboardService's shape, but every count here is scoped to
 * review queues an internal user may or may not be permissioned to see,
 * rather than to a single partner's own records.
 */
public with sharing class InternalDashboardService {
  private static final Set<String> PENDING_DEAL_STATUSES = new Set<String>{
    'Submitted',
    'Under Review'
  };

  public static InternalDashboardDTO getDashboard() {
    PartnerAccessService.assertInternalUser();

    InternalDashboardDTO dto = new InternalDashboardDTO();
    dto.userName = UserInfo.getName();
    dto.alerts = new List<String>();

    dto.pendingDealReviewCount = 0;

    // Silently report zero rather than throwing when the user lacks the
    // review permission — this dashboard is shared by all internal users,
    // not just reviewers, and a permission gap here should not surface as
    // an error tile.
    if (PartnerPermissionService.canViewAllDeals()) {
      List<DealReviewListDTO> reviewQueue = DealReviewService.getReviewQueue();

      for (DealReviewListDTO deal : reviewQueue) {
        if (PENDING_DEAL_STATUSES.contains(deal.status)) {
          dto.pendingDealReviewCount++;
        }
      }
    }

    dto.pendingMdfReviewCount = 0;

    if (PartnerPermissionService.canViewAllMdf()) {
      dto.pendingMdfReviewCount = MDFSelector.selectReviewQueue().size();
    }

    dto.unreadNotificationCount = NotificationSelector.countUnreadForUser(
      UserInfo.getUserId()
    );

    addDealAlert(dto.alerts, dto.pendingDealReviewCount);
    addMdfAlert(dto.alerts, dto.pendingMdfReviewCount);
    addNotificationAlert(dto.alerts, dto.unreadNotificationCount);

    return dto;
  }

  private static void addDealAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      count +
        (count == 1 ? ' deal registration is' : ' deal registrations are') +
        ' awaiting review.'
    );
  }

  private static void addMdfAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      count +
        (count == 1 ? ' MDF request is' : ' MDF requests are') +
        ' awaiting review.'
    );
  }

  private static void addNotificationAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      'You have ' +
        count +
        (count == 1 ? ' unread notification.' : ' unread notifications.')
    );
  }
}
