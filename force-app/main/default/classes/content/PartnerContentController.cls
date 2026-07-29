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
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerContentController',
        'Unable to load content.',
        ex
      );

      throw new AuraHandledException('Unable to load content.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerContentCategoryDTO> getCategories() {
    try {
      return PartnerContentService.getCategories();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerContentController',
        'Unable to load content categories.',
        ex
      );

      throw new AuraHandledException('Unable to load content categories.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerContentAdminDTO> getAllContent() {
    try {
      return PartnerContentService.getAllContentForAdmin();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerContentController',
        'Unable to load content for administration.',
        ex
      );

      throw new AuraHandledException(
        'Unable to load content for administration.'
      );
    }
  }

  @AuraEnabled
  public static PartnerContentAdminDTO saveContent(
    PartnerContentAdminDTO content
  ) {
    try {
      return PartnerContentService.saveContent(content);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerContentController',
        'Unable to save content.',
        ex
      );

      throw new AuraHandledException('Unable to save content.');
    }
  }

  @AuraEnabled
  public static PartnerContentDownloadDTO getDownloadUrl(Id contentId) {
    try {
      return PartnerContentService.getDownloadUrl(contentId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerContentController',
        'Unable to generate content download URL.',
        ex
      );

      throw new AuraHandledException('Unable to download content.');
    }
  }
}
