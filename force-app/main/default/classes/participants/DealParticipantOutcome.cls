/**
 * Result of an invitation attempt: a committed business outcome, per the
 * architecture doc's framing of invitation validation results as findings
 * that need to persist rather than silent exceptions for every case.
 */
public class DealParticipantOutcome {
  public static final String INVITED = 'Invited';
  public static final String ALREADY_PARTICIPATING = 'AlreadyParticipating';
  public static final String PARTNER_INELIGIBLE = 'PartnerIneligible';
  public static final String CO_SELL_NOT_PERMITTED = 'CoSellNotPermitted';
  public static final String RELATIONSHIP_REQUIRED = 'RelationshipRequired';

  public String outcome;
  public Deal_Participant__c participant;
  public String message;

  public DealParticipantOutcome(
    String outcome,
    Deal_Participant__c participant,
    String message
  ) {
    this.outcome = outcome;
    this.participant = participant;
    this.message = message;
  }
}
