/**
 * Generic success/failure envelope for callers that need a uniform shape
 * regardless of payload type (data is untyped Object). Prefer a specific
 * DTO when the shape is known ahead of time; use ok()/fail() rather than
 * constructing directly so success and errors stay in sync.
 */
public with sharing class PartnerSyncResponseDTO {
  /**
   * Whether the operation succeeded.
   */
  @AuraEnabled
  public Boolean success { get; set; }
  /**
   * Human-readable summary message for the operation.
   */
  @AuraEnabled
  public String message { get; set; }
  /**
   * The operation's result payload, when successful. Shape depends on the
   * caller.
   */
  @AuraEnabled
  public Object data { get; set; }
  /**
   * Error messages accumulated for a failed operation.
   */
  @AuraEnabled
  public List<String> errors { get; set; }

  /**
   * Creates an empty response with an initialized errors list.
   */
  public PartnerSyncResponseDTO() {
    this.errors = new List<String>();
  }

  /**
   * Builds a successful response wrapping the given payload.
   *
   * @param message Summary message describing the success.
   * @param data The result payload to return to the caller.
   * @return A PartnerSyncResponseDTO with success set to true.
   */
  public static PartnerSyncResponseDTO ok(String message, Object data) {
    PartnerSyncResponseDTO response = new PartnerSyncResponseDTO();
    response.success = true;
    response.message = message;
    response.data = data;
    return response;
  }

  /**
   * Builds a failed response carrying the given error message.
   *
   * @param message Description of the failure, also added to errors.
   * @return A PartnerSyncResponseDTO with success set to false.
   */
  public static PartnerSyncResponseDTO fail(String message) {
    PartnerSyncResponseDTO response = new PartnerSyncResponseDTO();
    response.success = false;
    response.message = message;
    response.errors.add(message);
    return response;
  }
}
