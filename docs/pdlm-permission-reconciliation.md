# PDLM Permission Reconciliation Matrix

This matrix reconciles the implemented Sprint 34–37 metadata with the existing
PartnerSync security model. Existing permission sets remain the primary model;
new sets are introduced only for operational or restricted authorities that
must not be inherited from a broad persona.

## Implemented object-name reconciliation

| Architecture concept              | Implemented metadata                                                                    |
| --------------------------------- | --------------------------------------------------------------------------------------- |
| Command execution ledger          | `Deal_Command_Execution__c`                                                             |
| Event publication outbox          | `Deal_Event_Outbox__c`                                                                  |
| Deal timeline                     | `Deal_Event__c`                                                                         |
| Validation result                 | `Deal_Validation_Finding__c`                                                            |
| Conflict analysis                 | `Deal_Conflict_Analysis_Run__c`                                                         |
| Conflict finding and waiver state | `Deal_Conflict__c`                                                                      |
| Review plan and work item         | `Deal_Review_Plan__c`, `Deal_Review__c`                                                 |
| Information cycle                 | `Deal_Information_Request__c`                                                           |
| Approval plan, step and condition | `Deal_Approval_Plan__c`, `Deal_Approval__c`, `Deal_Approval_Condition__c`               |
| Protection, extension and history | `Deal_Protection_Grant__c`, `Deal_Protection_Extension__c`, `Deal_Protection_Action__c` |

The proposed event-consumption, dead-letter, identity-snapshot, conflict-evidence,
review-evidence, delegation, authority-snapshot and protection-scope objects have
not been implemented. Permission metadata must be added with those objects, not
in advance.

## Existing permission-set decisions

| Existing set                        | Decision          | PDLM treatment                                                                                                                                                         |
| ----------------------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PartnerSync_Partner_User`          | Extend            | Partner-owned registration plus partner-safe validation visibility. Do not expose internal conflict, review, approval, command or event records.                       |
| `PartnerSync_Partner_Admin`         | Extend            | Same partner-safe boundary with account-level partner administration; it is not business approval authority.                                                           |
| `PartnerSync_Deal_Reviewer`         | Retain and reduce | Ordinary approve/reject/conflict resolution remains. Controlled lifecycle fields are read-only, record delete/Modify All is removed, and critical waiver is split out. |
| `PartnerSync_Channel_Manager`       | Extend            | Existing internal channel capability remains; the channel-manager group composes the reviewer capability.                                                              |
| `PartnerSync_PDLM_Admin`            | Retain and reduce | Configuration/control-plane access remains. Controlled lifecycle fields are read-only and critical business waiver authority is excluded.                              |
| MDF, Content, Analytics and AI sets | Retain            | Unrelated capability sets remain unchanged.                                                                                                                            |

## New capability sets

| New set                                   | Reason                                                            | Group placement        |
| ----------------------------------------- | ----------------------------------------------------------------- | ---------------------- |
| `PartnerSync_Command_Operations`          | Inspect/recover command execution without lifecycle authority     | Internal Administrator |
| `PartnerSync_Event_Operations`            | Inspect/replay internal events and manage outbox failures         | Internal Administrator |
| `PartnerSync_Critical_Conflict_Authority` | Separates critical waiver from ordinary review and administration | Direct assignment only |

`PSG_Internal_Administrator` composes PDLM administration and the two operational
sets. It deliberately excludes critical-conflict authority. `PSG_Channel_Manager`
composes the existing reviewer set but does not receive critical-waiver authority.

## Field and record-access rules

- Lifecycle state, version, lock, health and derived identity fields on
  `Deal_Registration__c` are readable but not directly editable in reviewer and
  PDLM administrator sets. Commands remain the mutation boundary.
- Partner permission sets do not receive direct access to internal conflict,
  review, approval, event, outbox or command-ledger objects.
- Critical conflict waiver remains a custom-permission check and is assigned only
  through `PartnerSync_Critical_Conflict_Authority`.
- Permission sets grant object/FLS capability; sharing sets, managed sharing and
  assignment rules must still grant record access independently.

## Follow-up gates

Before adding any optional aggregate, its story must include object metadata,
field classification, CRUD/FLS, custom-permission enforcement, group placement,
sharing behavior and security tests. Final approval authority cannot be split
from the existing `PartnerSync_Approve_Deal` behavior until the command contract
defines a distinct finalisation action and checks a dedicated custom permission.
