public with sharing class PartnerContentService {
  public static List<PartnerContentDTO> getAvailableContent() {
    if (!TenantConfigService.isContentEnabled()) {
      throw new PartnerSyncHandledException('Content Hub is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    Account partner = [
      SELECT Id, Partner_Tier__c, Partner_Type__c
      FROM Account
      WHERE Id = :partnerAccountId AND Is_Partner__c = TRUE
      LIMIT 1
    ];

    List<PartnerContentDTO> results = new List<PartnerContentDTO>();

    for (
      Partner_Content__c content : PartnerContentSelector.selectActiveContent()
    ) {
      if (PartnerContentDomain.isVisibleToPartner(content, partner)) {
        results.add(PartnerContentDomain.toDTO(content));
      }
    }

    return results;
  }

  public static PartnerContentDownloadDTO getDownloadUrl(Id contentId) {
    if (!TenantConfigService.isContentEnabled()) {
      throw new PartnerSyncHandledException('Content Hub is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Contact contact = PartnerAccessService.getCurrentPartnerContact();

    Account partner = [
      SELECT Id, Partner_Tier__c, Partner_Type__c
      FROM Account
      WHERE Id = :partnerAccountId AND Is_Partner__c = TRUE
      LIMIT 1
    ];

    Partner_Content__c content = PartnerContentSelector.selectById(contentId);

    if (!PartnerContentDomain.isVisibleToPartner(content, partner)) {
      throw new PartnerSyncHandledException('Content not accessible.');
    }

    if (String.isBlank(content.Content_Document_Id__c)) {
      throw new PartnerSyncHandledException(
        'No file is attached to this content.'
      );
    }

    logUsage(partnerAccountId, contact.Id, content.Id, 'Downloaded');

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'Partner_Content__c',
      content.Id,
      'Download'
    );

    audit.partnerAccountId = partnerAccountId;
    audit.partnerContactId = contact.Id;

    AuditService.log(audit);

    PartnerContentDownloadDTO dto = new PartnerContentDownloadDTO();
    dto.contentId = content.Id;
    dto.downloadUrl = buildDownloadUrl(content.Content_Document_Id__c);

    return dto;
  }

  private static String buildDownloadUrl(String contentDocumentId) {
    return URL.getOrgDomainUrl().toExternalForm() +
      '/sfc/servlet.shepherd/document/download/' +
      EncodingUtil.urlEncode(contentDocumentId, 'UTF-8');
  }

  private static void logUsage(
    Id partnerAccountId,
    Id partnerContactId,
    Id contentId,
    String action
  ) {
    if (!Schema.sObjectType.Content_Usage_Log__c.isCreateable()) {
      return;
    }

    Content_Usage_Log__c log = new Content_Usage_Log__c();
    log.Partner_Account__c = partnerAccountId;
    log.Partner_Contact__c = partnerContactId;
    log.Partner_Content__c = contentId;
    log.Action__c = action;
    log.Performed_By__c = UserInfo.getUserId();
    log.Performed_On__c = System.now();

    insert SecurityUtil.stripForCreate(new List<SObject>{ log });
  }
}
