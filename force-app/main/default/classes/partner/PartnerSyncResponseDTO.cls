/*
 * Generic success/failure envelope for callers that need a uniform shape
 * regardless of payload type (data is untyped Object). Prefer a specific
 * DTO when the shape is known ahead of time; use ok()/fail() rather than
 * constructing directly so success and errors stay in sync.
 */
public with sharing class PartnerSyncResponseDTO {
  @AuraEnabled
  public Boolean success { get; set; }
  @AuraEnabled
  public String message { get; set; }
  @AuraEnabled
  public Object data { get; set; }
  @AuraEnabled
  public List<String> errors { get; set; }

  public PartnerSyncResponseDTO() {
    this.errors = new List<String>();
  }

  public static PartnerSyncResponseDTO ok(String message, Object data) {
    PartnerSyncResponseDTO response = new PartnerSyncResponseDTO();
    response.success = true;
    response.message = message;
    response.data = data;
    return response;
  }

  public static PartnerSyncResponseDTO fail(String message) {
    PartnerSyncResponseDTO response = new PartnerSyncResponseDTO();
    response.success = false;
    response.message = message;
    response.errors.add(message);
    return response;
  }
}
