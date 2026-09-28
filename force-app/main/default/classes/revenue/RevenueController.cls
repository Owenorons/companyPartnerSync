/**
 * Aura controller surface for Sprint 41: the partner-facing revenue/
 * incentive summary and the internal Finance Workbench's 5 queue views.
 * Pure pass-through/exception-translation layer over the revenue/
 * command services and selectors - no business logic here.
 *
 * No PartnerShareService sharing exists for this domain (Known Adaptation
 * #8) - every partner-facing method here does its own explicit
 * Partner_Account__c ownership check rather than relying on Salesforce
 * sharing, per the doc's own stricter guidance for financial data (§41.54).
 */
public with sharing class RevenueController {
  /**
   * Loads a deal's revenue summary for the current user - internal users
   * see every revenue record, partner users see only rows for their own
   * partner account.
   *
   * @param dealId Id of the deal.
   * @return The deal's partner-safe revenue summaries.
   */
  @AuraEnabled(cacheable=true)
  public static List<RevenueSummaryDTO> getRevenueSummaries(Id dealId) {
    try {
      if (
        !PartnerAccessService.isInternalUser() &&
        !DealLifecyclePermissionService.hasPermission(
          'PartnerSync_View_Own_Revenue'
        )
      ) {
        throw new PartnerSyncHandledException(
          'Current user lacks authority to view revenue.'
        );
      }

      List<RevenueSummaryDTO> results = new List<RevenueSummaryDTO>();
      Id currentPartnerAccountId = PartnerAccessService.isInternalUser()
        ? null
        : PartnerAccessService.getCurrentPartnerAccountId();

      for (Deal_Revenue__c revenue : [
        SELECT
          Id,
          Deal__c,
          Partner_Account__c,
          Revenue_Type__c,
          Status__c,
          Net_Amount__c,
          CurrencyIsoCode,
          Revenue_Date__c
        FROM Deal_Revenue__c
        WHERE Deal__c = :dealId
        WITH SYSTEM_MODE
        ORDER BY CreatedDate DESC
      ]) {
        if (
          currentPartnerAccountId != null &&
          revenue.Partner_Account__c != currentPartnerAccountId
        ) {
          continue;
        }
        RevenueSummaryDTO dto = new RevenueSummaryDTO();
        dto.revenueId = revenue.Id;
        dto.dealId = revenue.Deal__c;
        dto.revenueType = revenue.Revenue_Type__c;
        dto.status = revenue.Status__c;
        dto.netAmount = revenue.Net_Amount__c;
        dto.currencyIsoCode = revenue.CurrencyIsoCode;
        dto.revenueDate = revenue.Revenue_Date__c;
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load the revenue summary.',
        'Unable to load the revenue summary.',
        ex
      );
    }
  }

  /**
   * Loads a deal's incentive summary for the current user, scoped the
   * same way getRevenueSummaries() is.
   *
   * @param dealId Id of the deal.
   * @return The deal's partner-safe incentive summaries.
   */
  @AuraEnabled(cacheable=true)
  public static List<IncentiveSummaryDTO> getIncentiveSummaries(Id dealId) {
    try {
      if (
        !PartnerAccessService.isInternalUser() &&
        !DealLifecyclePermissionService.hasPermission(
          'PartnerSync_View_Own_Incentives'
        )
      ) {
        throw new PartnerSyncHandledException(
          'Current user lacks authority to view incentives.'
        );
      }

      List<IncentiveSummaryDTO> results = new List<IncentiveSummaryDTO>();
      Id currentPartnerAccountId = PartnerAccessService.isInternalUser()
        ? null
        : PartnerAccessService.getCurrentPartnerAccountId();

      for (Partner_Incentive__c incentive : [
        SELECT
          Id,
          Deal__c,
          Partner_Account__c,
          Incentive_Type__c,
          Status__c,
          Calculated_Amount__c,
          Approved_Amount__c,
          Paid_Amount__c,
          CurrencyIsoCode,
          Eligibility_Date__c,
          Payment_Date__c
        FROM Partner_Incentive__c
        WHERE Deal__c = :dealId
        WITH SYSTEM_MODE
        ORDER BY CreatedDate DESC
      ]) {
        if (
          currentPartnerAccountId != null &&
          incentive.Partner_Account__c != currentPartnerAccountId
        ) {
          continue;
        }
        IncentiveSummaryDTO dto = new IncentiveSummaryDTO();
        dto.incentiveId = incentive.Id;
        dto.dealId = incentive.Deal__c;
        dto.incentiveType = incentive.Incentive_Type__c;
        dto.status = incentive.Status__c;
        dto.calculatedAmount = incentive.Calculated_Amount__c;
        dto.approvedAmount = incentive.Approved_Amount__c;
        dto.paidAmount = incentive.Paid_Amount__c;
        dto.currencyIsoCode = incentive.CurrencyIsoCode;
        dto.eligibilityDate = incentive.Eligibility_Date__c;
        dto.paymentDate = incentive.Payment_Date__c;
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load the incentive summary.',
        'Unable to load the incentive summary.',
        ex
      );
    }
  }

  /**
   * Loads open/manual-review revenue reconciliation rows, for the Finance
   * Workbench's "Unmatched Revenue" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Revenue_Reconciliation__c> getUnmatchedRevenue() {
    try {
      PartnerAccessService.assertInternalUser();
      return RevenueReconciliationSelector.selectOpen();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load unmatched revenue.',
        'Unable to load unmatched revenue.',
        ex
      );
    }
  }

  /**
   * Loads overridden attribution rows, for the Finance Workbench's
   * "Attribution Exceptions" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Deal_Revenue_Attribution__c> getAttributionExceptions() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Revenue__c,
          Deal__c,
          Partner_Account__c,
          Attribution_Type__c,
          Attribution_Percentage__c,
          Override_Reason__c
        FROM Deal_Revenue_Attribution__c
        WHERE Status__c = 'Overridden'
        WITH SYSTEM_MODE
        ORDER BY CreatedDate DESC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load attribution exceptions.',
        'Unable to load attribution exceptions.',
        ex
      );
    }
  }

  /**
   * Loads incentive claims awaiting review, for the Finance Workbench's
   * "Claims Under Review" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Incentive_Claim__c> getClaimsUnderReview() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Incentive__c,
          Submitted_By__c,
          Submitted_On__c,
          Claimed_Amount__c,
          Status__c
        FROM Partner_Incentive_Claim__c
        WHERE Status__c IN ('Submitted', 'Under Review', 'Information Required')
        WITH SYSTEM_MODE
        ORDER BY Submitted_On__c ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load claims under review.',
        'Unable to load claims under review.',
        ex
      );
    }
  }

  /**
   * Loads incentives approved but not yet paid, for the Finance
   * Workbench's "Payment Pending" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Incentive__c> getPaymentPending() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Deal__c,
          Partner_Account__c,
          Incentive_Type__c,
          Status__c,
          Approved_Amount__c,
          CurrencyIsoCode
        FROM Partner_Incentive__c
        WHERE Status__c IN ('Approved', 'Payment Pending')
        WITH SYSTEM_MODE
        ORDER BY Approval_Date__c ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load payments pending.',
        'Unable to load payments pending.',
        ex
      );
    }
  }

  /**
   * Loads open/under-review revenue disputes, for the Finance Workbench's
   * "Open Disputes" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Revenue_Dispute__c> getOpenDisputes() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Partner_Account__c,
          Deal__c,
          Dispute_Type__c,
          Status__c,
          Description__c,
          Submitted_On__c
        FROM Partner_Revenue_Dispute__c
        WHERE Status__c IN ('Open', 'Under Review')
        WITH SYSTEM_MODE
        ORDER BY Submitted_On__c ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to load open disputes.',
        'Unable to load open disputes.',
        ex
      );
    }
  }

  /**
   * Submits a claim for an incentive that requires one.
   *
   * @param command incentiveId + claimedAmount + claimReason.
   * @return The inserted claim record.
   */
  @AuraEnabled
  public static Partner_Incentive_Claim__c submitClaim(
    IncentiveClaimCommand command
  ) {
    try {
      return IncentiveClaimCommandService.submit(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to submit the incentive claim.',
        'Unable to submit the incentive claim.',
        ex
      );
    }
  }

  /**
   * Opens a revenue dispute. A partner caller's own partner account is
   * resolved server-side - the LWC never needs to know or supply its own
   * Partner_Account__c, and can't spoof another partner's.
   *
   * @param command dealId/revenueId/etc. + disputeType + description (partnerAccountId is ignored for a partner caller).
   * @return The inserted dispute record.
   */
  @AuraEnabled
  public static Partner_Revenue_Dispute__c openDispute(
    RevenueDisputeCommand command
  ) {
    try {
      if (!PartnerAccessService.isInternalUser()) {
        command.partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
      }
      return RevenueDisputeCommandService.open(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'RevenueController',
        'Unable to open the revenue dispute.',
        'Unable to open the revenue dispute.',
        ex
      );
    }
  }
}
