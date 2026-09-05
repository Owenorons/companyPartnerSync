/*
 * Aura-enabled controller for the Partner Content Hub (browse, categories,
 * admin management, download). Thin pass-through to PartnerContentService —
 * all business/permission logic lives there; this layer only translates
 * handled vs. unexpected exceptions into AuraHandledException.
 */
public with sharing class PartnerContentController {
  @AuraEnabled(cacheable=true)
  public static List<PartnerContentDTO> getAvailableContent() {
    try {
      return PartnerContentService.getAvailableContent();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerContentController',
        'Unable to load content.',
        'Unable to load content.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerContentCategoryDTO> getCategories() {
    try {
      return PartnerContentService.getCategories();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerContentController',
        'Unable to load content categories.',
        'Unable to load content categories.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerContentAdminDTO> getAllContent() {
    try {
      return PartnerContentService.getAllContentForAdmin();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerContentController',
        'Unable to load content for administration.',
        'Unable to load content for administration.',
        ex
      );
    }
  }

  @AuraEnabled
  public static PartnerContentAdminDTO saveContent(
    PartnerContentAdminDTO content
  ) {
    try {
      return PartnerContentService.saveContent(content);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerContentController',
        'Unable to save content.',
        'Unable to save content.',
        ex
      );
    }
  }

  @AuraEnabled
  public static PartnerContentDownloadDTO getDownloadUrl(Id contentId) {
    try {
      return PartnerContentService.getDownloadUrl(contentId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerContentController',
        'Unable to generate content download URL.',
        'Unable to download content.',
        ex
      );
    }
  }
}
