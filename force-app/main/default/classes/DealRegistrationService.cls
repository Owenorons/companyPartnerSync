public with sharing class DealRegistrationService {
  public static DealRegistrationResultDTO createDealRegistration(
    DealRegistrationRequestDTO request
  ) {
    DealRegistrationDomain.validate(request);

    SecurityUtil.assertCreateable(Deal_Registration__c.SObjectType);

    Opportunity opportunity = [
      SELECT Id, AccountId, Partner_Account__c, Partner_Contact__c, StageName
      FROM Opportunity
      WHERE Id = :request.opportunityId
      LIMIT 1
    ];

    Id currentPartnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    if (opportunity.Partner_Account__c != currentPartnerAccountId) {
      throw new PartnerSyncHandledException(
        'Opportunity does not belong to the current partner.'
      );
    }

    Deal_Registration__c record = createDealRegistrationInternal(
      opportunity,
      request
    );

    return DealRegistrationDomain.toDTO(record);
  }

  public static List<DealRegistrationListDTO> getMyDeals() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<DealRegistrationListDTO> results = new List<DealRegistrationListDTO>();

    for (
      Deal_Registration__c record : DealRegistrationSelector.selectPartnerDeals(
        partnerAccountId
      )
    ) {
      results.add(DealRegistrationDomain.toListDTO(record));
    }

    return results;
  }

  // public static Deal_Registration__c createDealRegistrationInternal(Opportunity opportunity,DealRegistrationRequestDTO request
  // ) {
  //     Deal_Registration__c record =
  //         DealRegistrationDomain.buildRecord(
  //             opportunity,
  //             request
  //         );

  //     List<SObject> sanitized =
  //         SecurityUtil.stripForCreate(
  //             new List<SObject>{ record }
  //         );

  //     insert sanitized;

  //     Deal_Registration__c insertedRecord =
  //         (Deal_Registration__c) sanitized[0];

  //     DealConflictDTO conflict =
  //         DealConflictService.analyze(
  //             insertedRecord
  //         );

  //     insertedRecord.Conflict_Status__c =
  //         conflict.conflictStatus;

  //     if (!conflict.hasConflict) {

  //         insertedRecord.Status__c =
  //             'Approved';

  //         insertedRecord.Protection_End_Date__c =
  //             Date.today().addDays(
  //                 TenantConfigService.getDealExpiryDays()
  //             );
  //     }

  //     update SecurityUtil.stripForUpdate(
  //         new List<SObject>{ insertedRecord }
  //     );

  //     LoggingService.info(
  //         'DealRegistrationService',
  //         'Deal registration created. DealId=' +
  //         insertedRecord.Id
  //     );

  //     return insertedRecord;
  // }

  public static Deal_Registration__c createDealRegistrationInternal(
    Opportunity opportunity,
    DealRegistrationRequestDTO request
  ) {
    Deal_Registration__c record = DealRegistrationDomain.buildRecord(
      opportunity,
      request
    );

    List<SObject> sanitized = SecurityUtil.stripForCreate(
      new List<SObject>{ record }
    );

    insert sanitized;

    Deal_Registration__c insertedRecord = (Deal_Registration__c) sanitized[0];

    DealConflictDTO conflict = DealConflictService.analyze(insertedRecord);

    /*
     * Enterprise Governance Pattern
     *
     * ALL deals require internal review.
     *
     * No conflict:
     *      Submitted + No Conflict
     *
     * Conflict:
     *      Under Review + Potential Conflict
     */

    if (conflict.hasConflict) {
      insertedRecord.Status__c = 'Under Review';

      insertedRecord.Conflict_Status__c = 'Potential Conflict';
    } else {
      insertedRecord.Status__c = 'Submitted';

      insertedRecord.Conflict_Status__c = 'No Conflict';
    }

    update SecurityUtil.stripForUpdate(new List<SObject>{ insertedRecord });

    LoggingService.info(
      'DealRegistrationService',
      'Deal registration created. DealId=' + insertedRecord.Id
    );

    return insertedRecord;
  }
}
