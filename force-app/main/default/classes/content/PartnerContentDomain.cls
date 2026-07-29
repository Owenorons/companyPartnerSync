/*
 * Pure visibility and mapping rules for Partner_Content__c: decides which
 * content a given partner account may see and converts records to their
 * partner-facing / admin DTOs. No SOQL or DML, so the visibility rules can
 * be unit tested without inserting records.
 */
public with sharing class PartnerContentDomain {
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

    return dto;
  }

  public static void validateAdminSave(PartnerContentAdminDTO dto) {
    if (dto == null || dto.contentId == null) {
      throw new PartnerSyncHandledException('Content Id is required.');
    }

    if (String.isBlank(dto.title)) {
      throw new PartnerSyncHandledException('Title is required.');
    }
  }

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

    return content;
  }
}
