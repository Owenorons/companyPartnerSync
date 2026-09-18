/**
 * DTO representing a single operational alert (e.g. a recurring failure or
 * anomaly) shown on the internal dashboard.
 */
public class OperationalAlertDTO {
  /**
   * Id of the record the alert relates to.
   */
  @AuraEnabled
  public Id recordId { get; set; }
  /**
   * Type/category of the alert.
   */
  @AuraEnabled
  public String alertType { get; set; }
  /**
   * Severity of the alert.
   */
  @AuraEnabled
  public String severity { get; set; }
  /**
   * Human-readable message describing the alert.
   */
  @AuraEnabled
  public String message { get; set; }
  /**
   * Number of times this alert condition has been detected.
   */
  @AuraEnabled
  public Integer occurrenceCount { get; set; }
  /**
   * Timestamp the alert was most recently detected.
   */
  @AuraEnabled
  public Datetime lastDetectedOn { get; set; }
  /**
   * Current status of the alert (e.g. open, acknowledged, resolved).
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Timestamp the alert was resolved, if applicable.
   */
  @AuraEnabled
  public Datetime resolvedOn { get; set; }
  /**
   * Whether the running user is allowed to acknowledge this alert.
   */
  @AuraEnabled
  public Boolean canAcknowledge { get; set; }
  /**
   * Label for the next available status transition action.
   */
  @AuraEnabled
  public String transitionLabel { get; set; }
}
