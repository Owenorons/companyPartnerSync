/**
 * Data carrier for a single lifecycle command submitted to DealCommandService: identifies the
 * target deal/aggregate, the requested command type, an idempotency key, and any
 * command-specific parameters.
 */
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

  /**
   * Creates a new command with an initialized, empty parameters map.
   */
  public DealCommand() {
    parameters = new Map<String, Object>();
  }

  /**
   * Validates that this command has the fields required to be executed: deal and aggregate
   * identifiers, an aggregate type and lifecycle dimension, a command type, and a command key no
   * longer than 80 characters. Also ensures parameters is non-null.
   */
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
