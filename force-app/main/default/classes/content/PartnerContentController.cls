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
