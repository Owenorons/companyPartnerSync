trigger PartnerSyncEventTrigger on PartnerSync_Event__e(after insert) {
  PartnerSyncEventHandler.handle(Trigger.new);
}
