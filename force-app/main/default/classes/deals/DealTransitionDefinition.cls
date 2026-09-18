/**
 * In-memory representation of a configured deal state transition (from the
 * Deal_State_Transition__mdt custom metadata type), describing the allowed
 * from/to states, handler, permissions, and actor eligibility for an action.
 */
public class DealTransitionDefinition {
  public String aggregateType;
  public String lifecycleDimension;
  public String fromState;
  public String action;
  public String toState;
  public String requiredPermission;
  public String handlerClass;
  public String eventType;
  public Boolean partnerVisible;
  public Boolean requiresReason;
  public Boolean requiresVersion;
  public Boolean allowPartner;
  public Boolean allowInternal;
}
