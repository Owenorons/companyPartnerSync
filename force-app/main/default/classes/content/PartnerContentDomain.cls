/**
 * Pure visibility and mapping rules for Partner_Content__c: decides which
 * content a given partner account may see and converts records to their
 * partner-facing / admin DTOs. No SOQL or DML, so the visibility rules can
 * be unit tested without inserting records.
 */
public with sharing class PartnerContentDomain {
  /**
   * Determines whether a content record should be visible to the given
   * partner account: it must be active, not marked Internal Only, and
   * either visible to All Partners or (for Restricted content) match
   * the partner's tier and/or type — a blank tier or type on the
   * content record is treated as matching any partner on that
   * dimension.
   *
   * @param content The content record to evaluate.
   * @param partner The partner account's Account record.
   * @return True if the content should be visible to the partner.
   */
  public static Boolean isVisibleToPartner(
    Partner_Content__c content,
    Account partner
  ) {
    if (content == null || partner == null) {
      return false;
    }

    if (!content.Is_Active__c) {
      return false;
    }

    if (content.Visibility__c == 'Internal Only') {
      return false;
    }

    if (content.Visibility__c == 'All Partners') {
      return true;
    }

    if (content.Visibility__c == 'Restricted') {
      // A blank Tier/Type on the content record is treated as "matches any
      // partner" (a wildcard), not "matches none" — lets admins restrict on
      // just one dimension (e.g. tier only) without needing to fill both.
      Boolean tierMatches =
        String.isBlank(content.Partner_Tier__c) ||
        content.Partner_Tier__c == partner.Partner_Tier__c;

      Boolean typeMatches =
        String.isBlank(content.Partner_Type__c) ||
        content.Partner_Type__c == partner.Partner_Type__c;

      return tierMatches && typeMatches;
    }

    return false;
  }

  /**
   * Converts a Partner_Content__c record into its partner-facing DTO.
   *
   * @param content The content record to convert.
   * @return The corresponding partner-facing DTO.
   */
  public static PartnerContentDTO toDTO(Partner_Content__c content) {
    PartnerContentDTO dto = new PartnerContentDTO();

    dto.contentId = content.Id;
    dto.title = content.Name;
    dto.description = content.Description__c;
    dto.category = content.Category__c;
    dto.featured = content.Featured__c;
    dto.publishedDate = content.Published_Date__c;

    return dto;
  }

  /**
   * Converts a Partner_Content__c record into its admin DTO, including
   * the visibility/targeting/lifecycle fields partners never see.
   *
   * @param content The content record to convert.
   * @return The corresponding admin DTO.
   */
  public static PartnerContentAdminDTO toAdminDTO(Partner_Content__c content) {
    PartnerContentAdminDTO dto = new PartnerContentAdminDTO();

    dto.contentId = content.Id;
    dto.title = content.Name;
    dto.description = content.Description__c;
    dto.category = content.Category__c;
    dto.featured = content.Featured__c;
    dto.isActive = content.Is_Active__c;
    dto.visibility = content.Visibility__c;
    dto.partnerTier = content.Partner_Tier__c;
    dto.partnerType = content.Partner_Type__c;
    dto.sortOrder = content.Sort_Order__c;
    dto.contentDocumentId = content.Content_Document_Id__c;

    return dto;
  }

  /**
   * Validates that an admin content save has the fields required to
   * persist it, throwing if not. A new record (contentId blank) also
   * requires a file, since content with nothing to download isn't a
   * usable asset; an update to an existing record may omit the file to
   * leave the previously attached one in place.
   *
   * @param dto The admin content payload to validate.
   */
  public static void validateAdminSave(PartnerContentAdminDTO dto) {
    if (dto == null) {
      throw new PartnerSyncHandledException('Content details are required.');
    }

    if (String.isBlank(dto.title)) {
      throw new PartnerSyncHandledException('Title is required.');
    }

    if (dto.contentId == null && dto.contentDocumentId == null) {
      throw new PartnerSyncHandledException(
        'A file upload is required for new content.'
      );
    }
  }

  /**
   * Applies an admin DTO's editable fields onto a Partner_Content__c
   * record, in place. The attached file is only replaced when the DTO
   * carries a contentDocumentId; leaving it blank on an update keeps the
   * record's existing file.
   *
   * @param content The content record to update.
   * @param dto The admin payload whose fields should be applied.
   * @return The same content record, updated with the DTO's fields.
   */
  public static Partner_Content__c applyAdminUpdate(
    Partner_Content__c content,
    PartnerContentAdminDTO dto
  ) {
    content.Name = dto.title;
    content.Description__c = dto.description;
    content.Category__c = dto.category;
    content.Featured__c = dto.featured == true;
    content.Is_Active__c = dto.isActive == true;
    content.Visibility__c = dto.visibility;
    content.Partner_Tier__c = dto.partnerTier;
    content.Partner_Type__c = dto.partnerType;
    content.Sort_Order__c = dto.sortOrder;
    if (dto.contentDocumentId != null) {
      content.Content_Document_Id__c = dto.contentDocumentId;
    }

    return content;
  }
}
