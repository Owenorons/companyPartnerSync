/**
 * Orchestrates the deal conflict workbench read side: lists and loads
 * findings for the running user, gated by the same
 * PartnerSync_Resolve_Deal_Conflict permission DealConflictCommandService
 * already requires to act on one - there's no separate "view only" access
 * today, so anyone who can see the queue can also work it.
 */
public with sharing class DealConflictWorkbenchService {
  private static final String RESOLVE_PERMISSION = 'PartnerSync_Resolve_Deal_Conflict';

  /**
   * Loads every current, non-terminal conflict finding.
   *
   * @return Row shapes for the workbench queue.
   */
  public static List<DealConflictWorkbenchListDTO> getPendingConflicts() {
    assertAuthority();

    List<DealConflictWorkbenchListDTO> results = new List<DealConflictWorkbenchListDTO>();

    for (
      Deal_Conflict__c record : DealConflictSelector.selectPendingConflicts()
    ) {
      results.add(DealConflictWorkbenchDomain.toListDTO(record));
    }

    return results;
  }

  /**
   * Loads the full detail for a single conflict finding.
   *
   * @param conflictId Id of the conflict finding to load.
   * @return The full detail DTO for the finding.
   */
  public static DealConflictWorkbenchDetailDTO getConflictDetail(
    Id conflictId
  ) {
    assertAuthority();

    Deal_Conflict__c record = DealConflictSelector.selectConflictDetail(
      conflictId
    );

    return DealConflictWorkbenchDomain.toDetailDTO(record);
  }

  private static void assertAuthority() {
    if (!DealLifecyclePermissionService.hasPermission(RESOLVE_PERMISSION)) {
      throw new PartnerSyncHandledException(
        'You do not have permission to work deal conflicts.'
      );
    }
  }
}
