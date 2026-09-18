/**
 * Mutable execution context passed through evaluation and handling of a deal
 * lifecycle command, carrying the deal, command, resolved transition, and
 * the resulting state change and event data.
 */
public class DealCommandContext {
  public Deal_Registration__c deal;
  public DealCommand command;
  public DealTransitionDefinition transition;
  public String previousState;
  public String newState;
  public Integer previousVersion;
  public Integer newVersion;
  public String eventType;
  public Map<String, Object> eventPayload = new Map<String, Object>();
}
