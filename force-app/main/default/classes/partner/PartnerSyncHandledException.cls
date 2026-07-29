/*
 * Marker exception for expected, user-facing business-rule failures (bad
 * input, missing permission, invalid state) across the partner domain.
 * Controllers catch this type specifically to surface ex.getMessage()
 * directly to the UI, while any other Exception is logged and masked behind
 * a generic message — so throwing this vs. a plain Exception is a deliberate
 * choice about what the end user is allowed to see.
 */
public class PartnerSyncHandledException extends Exception {
}
