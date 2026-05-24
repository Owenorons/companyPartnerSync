public with sharing class SecurityUtil {
  public static void assertReadable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isAccessible()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to read this data.'
      );
    }
  }

  public static void assertCreateable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isCreateable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to create this record.'
      );
    }
  }

  public static void assertUpdateable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isUpdateable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to update this record.'
      );
    }
  }

  public static void assertDeleteable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isDeletable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to delete this record.'
      );
    }
  }

  public static List<SObject> stripForCreate(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    return Security.stripInaccessible(AccessType.CREATABLE, records)
      .getRecords();
  }

  public static List<SObject> stripForUpdate(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    return Security.stripInaccessible(AccessType.UPDATABLE, records)
      .getRecords();
  }

  public static List<SObject> stripForRead(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    return Security.stripInaccessible(AccessType.READABLE, records)
      .getRecords();
  }

  public static void assertFieldReadable(
    Schema.SObjectType objectType,
    String fieldApiName
  ) {
    Schema.DescribeSObjectResult objDescribe = objectType.getDescribe();
    Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();

    if (!fields.containsKey(fieldApiName)) {
      throw new PartnerSyncHandledException('Invalid field reference.');
    }

    if (!fields.get(fieldApiName).getDescribe().isAccessible()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to read this field.'
      );
    }
  }

  public static void assertFieldCreateable(
    Schema.SObjectType objectType,
    String fieldApiName
  ) {
    Schema.DescribeSObjectResult objDescribe = objectType.getDescribe();
    Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();

    if (!fields.containsKey(fieldApiName)) {
      throw new PartnerSyncHandledException('Invalid field reference.');
    }

    if (!fields.get(fieldApiName).getDescribe().isCreateable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to create this field.'
      );
    }
  }

  public static void assertFieldUpdateable(
    Schema.SObjectType objectType,
    String fieldApiName
  ) {
    Schema.DescribeSObjectResult objDescribe = objectType.getDescribe();
    Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();

    if (!fields.containsKey(fieldApiName)) {
      throw new PartnerSyncHandledException('Invalid field reference.');
    }

    if (!fields.get(fieldApiName).getDescribe().isUpdateable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to update this field.'
      );
    }
  }
}
