/**
 * Executes Partner_Incentive_Payment__c commands: record, reverse. No
 * PartnerIncentivePaymentAdapter implementation exists (Known Adaptation
 * #3), so record() takes the payment status directly from the caller
 * rather than a live payment-system callout - manual entry is the only
 * real path today, same reasoning as ManualRevenueAdapter.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class IncentivePaymentCommandService {
  /**
   * Records a payment against an approved incentive.
   *
   * @param command incentiveId + amount + paymentReference/paymentSystem.
   * @return The inserted payment record.
   */
  public static Partner_Incentive_Payment__c record(
    IncentivePaymentCommand command
  ) {
    assertAuthority();
    if (command.incentiveId == null || command.amount == null) {
      throw new PartnerSyncHandledException(
        'An incentive and an amount are required to record a payment.'
      );
    }

    Partner_Incentive__c incentive = IncentiveSelector.selectForUpdate(
      command.incentiveId
    );
    if (
      incentive.Status__c != 'Approved' &&
      incentive.Status__c != 'Payment Pending'
    ) {
      throw new PartnerSyncHandledException(
        'This incentive is not in a state that can be paid.'
      );
    }

    Partner_Incentive_Payment__c payment = new Partner_Incentive_Payment__c(
      Incentive__c = incentive.Id,
      Partner_Account__c = incentive.Partner_Account__c,
      Amount__c = command.amount,
      Payment_Reference__c = command.paymentReference,
      Payment_System__c = command.paymentSystem,
      Status__c = 'Paid',
      Paid_On__c = System.now()
    );
    Database.insert(payment, AccessLevel.SYSTEM_MODE);

    incentive.Paid_Amount__c =
      (incentive.Paid_Amount__c == null ? 0 : incentive.Paid_Amount__c) +
      command.amount;
    incentive.Payment_Date__c = Date.today();
    incentive.Status__c = 'Paid';
    incentive.Version_Number__c = incentive.Version_Number__c == null
      ? 1
      : Integer.valueOf(incentive.Version_Number__c) + 1;
    Database.update(incentive, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerIncentivePaid',
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      'A partner incentive was paid.',
      'Info'
    );

    return payment;
  }

  /**
   * Reverses a payment by creating a compensating record rather than
   * mutating the original (doc §41.41), and returns the incentive to
   * Approved so it can be re-paid.
   *
   * @param command paymentId + reason.
   * @return The compensating payment record.
   */
  public static Partner_Incentive_Payment__c reverse(
    IncentivePaymentCommand command
  ) {
    assertAuthority();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Reverse_Incentive'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to reverse an incentive payment.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to reverse an incentive payment.'
      );
    }
    if (command.paymentId == null) {
      throw new PartnerSyncHandledException(
        'A payment is required for this command.'
      );
    }

    Partner_Incentive_Payment__c payment = IncentivePaymentSelector.selectForUpdate(
      command.paymentId
    );
    if (payment.Status__c == 'Reversed') {
      throw new PartnerSyncHandledException(
        'This payment has already been reversed.'
      );
    }

    Partner_Incentive_Payment__c compensating = new Partner_Incentive_Payment__c(
      Incentive__c = payment.Incentive__c,
      Partner_Account__c = payment.Partner_Account__c,
      Amount__c = payment.Amount__c == null ? null : -payment.Amount__c,
      Payment_Reference__c = 'Reversal of ' + payment.Payment_Reference__c,
      Payment_System__c = payment.Payment_System__c,
      Status__c = 'Reversed',
      Paid_On__c = System.now()
    );
    Database.insert(compensating, AccessLevel.SYSTEM_MODE);

    payment.Status__c = 'Reversed';
    Database.update(payment, AccessLevel.SYSTEM_MODE);

    Partner_Incentive__c incentive = IncentiveSelector.selectForUpdate(
      payment.Incentive__c
    );
    incentive.Paid_Amount__c =
      (incentive.Paid_Amount__c == null ? 0 : incentive.Paid_Amount__c) -
      (payment.Amount__c == null ? 0 : payment.Amount__c);
    incentive.Status__c = 'Approved';
    incentive.Version_Number__c = incentive.Version_Number__c == null
      ? 1
      : Integer.valueOf(incentive.Version_Number__c) + 1;
    Database.update(incentive, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerIncentivePaymentFailed',
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      'A partner incentive payment was reversed: ' + command.reason,
      'Warning'
    );

    return compensating;
  }

  private static void assertAuthority() {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Revenue_Reconciliation'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to manage incentive payments.'
      );
    }
  }
}
