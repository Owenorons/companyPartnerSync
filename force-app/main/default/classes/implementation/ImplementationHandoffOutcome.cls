/**
 * Result of a submitHandoff attempt: a committed business outcome per the
 * same framing DealParticipantOutcome/DealOpportunityOutcome established.
 * Trimmed from the architecture doc's full outcome set (§40.11) to the 5
 * reachable outcomes this codebase has real signal for - CommercialIssueOpen
 * is dropped since nothing in this codebase tracks open commercial
 * disputes to check against.
 */
public class ImplementationHandoffOutcome {
  public static final String ACCEPTED = 'Accepted';
  public static final String INFORMATION_REQUIRED = 'InformationRequired';
  public static final String EVIDENCE_REQUIRED = 'EvidenceRequired';
  public static final String DELIVERY_OWNER_REQUIRED = 'DeliveryOwnerRequired';
  public static final String SCOPE_INCOMPLETE = 'ScopeIncomplete';

  public String outcome;
  public Deal_Implementation_Handoff__c handoff;
  public String message;

  public ImplementationHandoffOutcome(
    String outcome,
    Deal_Implementation_Handoff__c handoff,
    String message
  ) {
    this.outcome = outcome;
    this.handoff = handoff;
    this.message = message;
  }
}
