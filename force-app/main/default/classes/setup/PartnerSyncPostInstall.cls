/*
 * Stable subscriber-callable facade for the small set of post-install
 * operations that must execute inside the managed namespace. Keep internal
 * implementation classes public so they don't become permanent global APIs.
 */
global with sharing class PartnerSyncPostInstall {
  global static void scheduleOperationalAutomation() {
    PartnerSyncSetupController.configureOperationalAutomation();
  }
}
