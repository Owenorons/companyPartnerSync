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
}
