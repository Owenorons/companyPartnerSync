public class OperationalAlertDTO {
  @AuraEnabled
  public Id recordId { get; set; }
  @AuraEnabled
  public String alertType { get; set; }
  @AuraEnabled
  public String severity { get; set; }
  @AuraEnabled
  public String message { get; set; }
  @AuraEnabled
  public Integer occurrenceCount { get; set; }
  @AuraEnabled
  public Datetime lastDetectedOn { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public Datetime resolvedOn { get; set; }
  @AuraEnabled
  public Boolean canAcknowledge { get; set; }
  @AuraEnabled
  public String transitionLabel { get; set; }
}
