/**
 * Strategy interface for selecting which partner account a lead should be
 * distributed to from a pool of eligible candidates. Implementations
 * perform no DML - LeadDistributionService.distributeLead() applies the
 * result. Mirrors DealConflictRule/DealValidationRule's "pure evaluation,
 * caller persists" shape.
 */
public interface LeadAssignmentStrategy {
  /**
   * Selects one partner account Id from the given eligible candidates.
   *
   * @param candidatePartnerAccountIds Ids of the eligible partner accounts to choose from.
   * @return The selected partner account Id, or null if no candidate could be selected.
   */
  Id selectPartner(List<Id> candidatePartnerAccountIds);
}
