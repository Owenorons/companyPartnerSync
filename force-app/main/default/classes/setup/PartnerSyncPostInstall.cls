/**
 * Stable subscriber-callable facade for the small set of post-install
 * operations that must execute inside the managed namespace. Keep internal
 * implementation classes public so they don't become permanent global APIs.
 */
global with sharing class PartnerSyncPostInstall {
  /**
   * Schedules the PartnerSync operational automation jobs (lifecycle
   * governance, alerts, provisioning reconciliation, deal expiry, share
   * cleanup) in the subscriber org, if not already scheduled.
   */
  global static void scheduleOperationalAutomation() {
    PartnerSyncSetupController.configureOperationalAutomation();
  }
}
