/*
 * PartnerSync post-install scheduler.
 *
 * Run once in each subscriber org after installing or upgrading PartnerSync:
 * sf apex run --file scripts/apex/schedule-partnersync-operations.apex --target-org <alias>
 *
 * Safe to run again: active jobs with the same names are retained.
 */
psync.PartnerSyncPostInstall.scheduleOperationalAutomation();
System.debug('PartnerSync operational automation is configured.');
