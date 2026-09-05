// Compatibility entry point. Managed implementation classes aren't subscriber
// APIs, so scheduling is performed through the package's supported facade.
psync.PartnerSyncPostInstall.scheduleOperationalAutomation();
System.debug('PartnerSync operational automation is configured.');
