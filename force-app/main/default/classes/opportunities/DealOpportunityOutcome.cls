/**
 * Result of a linkOpportunityToDeal attempt: a committed business outcome
 * per the same "findings that need to persist rather than silent
 * exceptions for every case" framing DealParticipantOutcome established
 * for invitations (doc §39.11's outcome set).
 */
public class DealOpportunityOutcome {
  public static final String LINKED = 'Linked';
  public static final String ALREADY_LINKED = 'AlreadyLinked';
  public static final String ACCOUNT_MISMATCH = 'AccountMismatch';
  public static final String COMMERCIAL_CONFLICT = 'CommercialConflict';
  public static final String PROTECTION_MISMATCH = 'ProtectionMismatch';
  public static final String OPPORTUNITY_CLOSED = 'OpportunityClosed';
  public static final String LINK_REQUIRES_REVIEW = 'LinkRequiresReview';

  public String outcome;
  public Deal_Opportunity__c relationship;
  public String message;

  public DealOpportunityOutcome(
    String outcome,
    Deal_Opportunity__c relationship,
    String message
  ) {
    this.outcome = outcome;
    this.relationship = relationship;
    this.message = message;
  }
}
