/**
 * Aura-enabled controller for the Partner Content Hub (browse, categories,
 * admin management, download). Thin pass-through to PartnerContentService —
 * all business/permission logic lives there; this layer only translates
 * handled vs. unexpected exceptions into AuraHandledException.
 */
public with sharing class PartnerContentController {
  /**
   * Returns the content visible to the running partner user.
   *
   * @return List of content items the caller may see.
   */
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

  /**
   * Returns the active category picklist values for content filtering.
   *
   * @return List of category label/value pairs.
   */
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

  /**
   * Returns all content records for the content-management admin UI.
   * Requires the manage-content permission.
   *
   * @return List of all content items as admin DTOs.
   */
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

  /**
   * Saves changes to a content record from the admin UI. Requires the
   * manage-content permission.
   *
   * @param content The content fields to save.
   * @return The saved content as an admin DTO.
   */
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

  /**
   * Resolves a download URL for a content record, after verifying the
   * running partner user has access to it.
   *
   * @param contentId Id of the Partner_Content__c record to download.
   * @return The content Id paired with its resolved download URL.
   */
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
