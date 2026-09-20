/**
 * @description Detects whether a deal registration overlaps with another
 * active registration for the same customer account.
 */
public with sharing class DealConflictService {
  /**
   * @description Checks the given deal registration against
   * DealRegistrationSelector.findConflictingDeals for other registrations
   * tied to the same customer account.
   * @param deal The deal registration being evaluated (reads
   * Customer_Account__c and Id).
   * @return A DealConflictDTO indicating whether a conflict was found and
   * which deal Ids it conflicts with.
   */
  public static DealConflictDTO analyze(Deal_Registration__c deal) {
    DealConflictDTO dto = new DealConflictDTO();

    List<Deal_Registration__c> conflicts = DealRegistrationSelector.findConflictingDeals(
      deal.Customer_Account__c,
      deal.Id
    );

    dto.conflictingDealIds = new List<Id>();

    if (conflicts.isEmpty()) {
      dto.hasConflict = false;
      dto.conflictStatus = 'No Conflict';
      dto.summary = 'No conflicting deals found.';

      return dto;
    }

    dto.hasConflict = true;

    dto.conflictStatus = 'Potential Conflict';

    for (Deal_Registration__c record : conflicts) {
      dto.conflictingDealIds.add(record.Id);
    }

    dto.summary = 'Potential overlapping deal registrations detected.';

    return dto;
  }
}
