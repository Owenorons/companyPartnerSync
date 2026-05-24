public with sharing class DealConflictService {
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
