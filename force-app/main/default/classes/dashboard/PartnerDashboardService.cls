/*
 * Assembles the partner-facing dashboard for the signed-in partner
 * contact's own account: open deal/lead/MDF counts and alerts. Mirrors
 * InternalDashboardService's shape, but every number here is scoped to a
 * single partner rather than an org-wide review queue, and each section
 * is gated by TenantConfigService feature flags rather than a permission
 * set, since Deals/Leads/MDF can each be switched off per tenant.
 */
public with sharing class PartnerDashboardService {
  private static final Set<String> OPEN_DEAL_STATUSES = new Set<String>{
    'Draft',
    'Submitted',
    'Under Review',
    'Approved'
  };

  private static final Set<String> CLOSED_MDF_STATUSES = new Set<String>{
    'Reimbursed',
    'Closed',
    'Rejected'
  };

  private static final Set<String> ACTIVE_CONFLICT_STATUSES = new Set<String>{
    'Potential Conflict',
    'Confirmed Conflict'
  };

  // Below 20% of annual MDF budget remaining triggers a dashboard warning.
  private static final Decimal LOW_BUDGET_THRESHOLD = 0.2;

  public static PartnerDashboardDTO getDashboard() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Account partner = PartnerDashboardSelector.selectPartnerAccount(
      partnerAccountId
    );

    PartnerDashboardDTO dto = new PartnerDashboardDTO();
    dto.partnerName = partner.Name;
    dto.partnerStatus = partner.Partner_Status__c;
    dto.partnerTier = partner.Partner_Tier__c;
    dto.alerts = new List<String>();

    Integer conflictedDealCount = 0;

    dto.openDealCount = 0;

    if (TenantConfigService.isDealsEnabled()) {
      for (
        DealRegistrationListDTO deal : DealRegistrationService.getMyDeals()
      ) {
        if (OPEN_DEAL_STATUSES.contains(deal.status)) {
          dto.openDealCount++;
        }

        if (ACTIVE_CONFLICT_STATUSES.contains(deal.conflictStatus)) {
          conflictedDealCount++;
        }
      }
    }

    dto.assignedLeadCount = 0;

    if (TenantConfigService.isLeadsEnabled()) {
      for (LeadDistributionDTO lead : LeadDistributionService.getMyLeads()) {
        if (lead.status == 'Assigned') {
          dto.assignedLeadCount++;
        }
      }
    }

    dto.openMdfCount = 0;

    if (TenantConfigService.isMdfEnabled()) {
      for (MDFListDTO request : MDFService.getMyRequests()) {
        if (!CLOSED_MDF_STATUSES.contains(request.status)) {
          dto.openMdfCount++;
        }
      }

      addLowBudgetAlert(dto.alerts);
    }

    addLeadAlert(dto.alerts, dto.assignedLeadCount);
    addConflictAlert(dto.alerts, conflictedDealCount);

    return dto;
  }

  private static void addLeadAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      count +
        (count == 1 ? ' lead is' : ' leads are') +
        ' awaiting your response.'
    );
  }

  private static void addConflictAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      count +
        (count == 1 ? ' deal registration has' : ' deal registrations have') +
        ' an unresolved conflict.'
    );
  }

  private static void addLowBudgetAlert(List<String> alerts) {
    MDFBudgetDTO budget = MDFService.getMyBudget();

    if (
      budget == null ||
      budget.annualBudget == null ||
      budget.annualBudget <= 0 ||
      budget.remainingBudget == null
    ) {
      return;
    }

    if (budget.remainingBudget / budget.annualBudget < LOW_BUDGET_THRESHOLD) {
      alerts.add('Your MDF budget is running low.');
    }
  }
}
