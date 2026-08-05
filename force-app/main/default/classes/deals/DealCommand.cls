public class DealCommand {
  @AuraEnabled
  public String aggregateType;
  @AuraEnabled
  public Id aggregateId;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String lifecycleDimension;
  @AuraEnabled
  public String commandType;
  @AuraEnabled
  public String commandKey;
  @AuraEnabled
  public String correlationId;
  @AuraEnabled
  public String causationId;
  @AuraEnabled
  public String source;
  @AuraEnabled
  public Integer expectedVersion;
  @AuraEnabled
  public String reason;
  @AuraEnabled
  public Map<String, Object> parameters;

  public DealCommand() {
    parameters = new Map<String, Object>();
  }

  public void validate() {
    if (dealId == null || aggregateId == null) {
      throw new DealLifecycleException(
        'Deal and aggregate identifiers are required.'
      );
    }
    if (String.isBlank(aggregateType) || String.isBlank(lifecycleDimension)) {
      throw new DealLifecycleException(
        'Aggregate type and lifecycle dimension are required.'
      );
    }
    if (String.isBlank(commandType)) {
      throw new DealLifecycleException('A command type is required.');
    }
    if (String.isBlank(commandKey) || commandKey.length() > 80) {
      throw new DealLifecycleException(
        'A unique command key of no more than 80 characters is required.'
      );
    }
    if (parameters == null) {
      parameters = new Map<String, Object>();
    }
  }
}
