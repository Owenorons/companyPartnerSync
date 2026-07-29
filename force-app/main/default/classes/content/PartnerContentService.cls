/*
 * Service layer for the Partner Content Hub: partner browsing (tenant-flag
 * gated, visibility filtered per PartnerContentDomain), admin CRUD (gated on
 * assertCanManageContent), and download issuance (gated on
 * assertPartnerAccessToContent, with usage logging + audit trail).
 */
public with sharing class PartnerContentService {
  public static List<PartnerContentDTO> getAvailableContent() {
    if (!TenantConfigService.isContentEnabled()) {
      throw new PartnerSyncHandledException('Content Hub is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    Account partner = PartnerContentSelector.selectPartnerVisibilityContext(
      partnerAccountId
    );

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

  public static List<PartnerContentCategoryDTO> getCategories() {
    List<PartnerContentCategoryDTO> results = new List<PartnerContentCategoryDTO>();

    Schema.DescribeFieldResult categoryField = Partner_Content__c.Category__c.getDescribe();
    List<Schema.PicklistEntry> entries = categoryField.getPicklistValues();

    for (Schema.PicklistEntry entry : entries) {
      if (!entry.isActive()) {
        continue;
      }

      PartnerContentCategoryDTO dto = new PartnerContentCategoryDTO();
      dto.label = entry.getLabel();
      dto.value = entry.getValue();
      results.add(dto);
    }

    return results;
  }

  public static List<PartnerContentAdminDTO> getAllContentForAdmin() {
    PartnerPermissionService.assertCanManageContent();

    List<PartnerContentAdminDTO> results = new List<PartnerContentAdminDTO>();

    List<Partner_Content__c> records = PartnerContentSelector.selectAllForAdmin();

    for (Partner_Content__c record : records) {
      results.add(PartnerContentDomain.toAdminDTO(record));
    }

    return results;
  }

  public static PartnerContentAdminDTO saveContent(PartnerContentAdminDTO dto) {
    PartnerPermissionService.assertCanManageContent();
    PartnerContentDomain.validateAdminSave(dto);

    Partner_Content__c content = PartnerContentSelector.selectById(
      dto.contentId
    );

    PartnerContentDomain.applyAdminUpdate(content, dto);

    SecurityUtil.assertUpdateable(Partner_Content__c.SObjectType);
    update SecurityUtil.stripForUpdate(new List<SObject>{ content });

    return PartnerContentDomain.toAdminDTO(content);
  }

  public static PartnerContentDownloadDTO getDownloadUrl(Id contentId) {
    if (!TenantConfigService.isContentEnabled()) {
      throw new PartnerSyncHandledException('Content Hub is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Contact contact = PartnerAccessService.getCurrentPartnerContact();

    PartnerRecordAccessService.assertPartnerAccessToContent(contentId);

    Partner_Content__c content = PartnerContentSelector.selectById(contentId);

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
    // Not a signed/expiring link — it's the standard ContentDocument
    // download servlet path, which relies on the requesting user's own
    // session auth. assertPartnerAccessToContent() above is what actually
    // gates access; this URL alone grants nothing.
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
    // Usage logging is best-effort: silently skip rather than throw if the
    // running user/profile can't create Content_Usage_Log__c, so a missing
    // permission never blocks the actual download.
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
