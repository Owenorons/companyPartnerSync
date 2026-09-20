/**
 * Central CRUD/FLS enforcement helpers used throughout the domain services.
 * The assert* methods fail fast with a user-facing PartnerSyncHandledException
 * before a query/DML runs (object- and field-level), while the strip*
 * methods (Security.stripInaccessible) silently drop inaccessible fields
 * from records already being written/read. Callers choose one style or the
 * other depending on whether a permission gap should hard-stop the user or
 * degrade quietly.
 */
public with sharing class SecurityUtil {
  /**
   * Throws a user-facing exception if the running user cannot read the
   * given object.
   *
   * @param objectType The SObject type to check read access for.
   */
  public static void assertReadable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isAccessible()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to read this data.'
      );
    }
  }

  /**
   * Throws a user-facing exception if the running user cannot create
   * records of the given object.
   *
   * @param objectType The SObject type to check create access for.
   */
  public static void assertCreateable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isCreateable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to create this record.'
      );
    }
  }

  /**
   * Throws a user-facing exception if the running user cannot update
   * records of the given object.
   *
   * @param objectType The SObject type to check update access for.
   */
  public static void assertUpdateable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isUpdateable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to update this record.'
      );
    }
  }

  /**
   * Throws a user-facing exception if the running user cannot delete
   * records of the given object.
   *
   * @param objectType The SObject type to check delete access for.
   */
  public static void assertDeleteable(Schema.SObjectType objectType) {
    if (!objectType.getDescribe().isDeletable()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to delete this record.'
      );
    }
  }

  /**
   * Removes fields the running user cannot create from each record,
   * degrading quietly rather than throwing.
   *
   * @param records The records to strip inaccessible fields from.
   * @return The records with any non-creatable fields removed.
   */
  public static List<SObject> stripForCreate(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    return Security.stripInaccessible(AccessType.CREATABLE, records)
      .getRecords();
  }

  /**
   * Removes fields the running user cannot update from each record,
   * degrading quietly rather than throwing.
   *
   * @param records The records to strip inaccessible fields from.
   * @return The records with any non-updatable fields removed.
   */
  public static List<SObject> stripForUpdate(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    return Security.stripInaccessible(AccessType.UPDATABLE, records)
      .getRecords();
  }

  /**
   * Removes fields the running user cannot read from each record,
   * degrading quietly rather than throwing.
   *
   * @param records The records to strip inaccessible fields from.
   * @return The records with any non-readable fields removed.
   */
  public static List<SObject> stripForRead(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    return Security.stripInaccessible(AccessType.READABLE, records)
      .getRecords();
  }

  /**
   * Throws a user-facing exception if the given field does not exist on the
   * object, or if the running user cannot read it.
   *
   * @param objectType The SObject type the field belongs to.
   * @param fieldApiName The API name of the field to check read access for.
   */
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

  /**
   * Throws a user-facing exception if the given field does not exist on the
   * object, or if the running user cannot create it.
   *
   * @param objectType The SObject type the field belongs to.
   * @param fieldApiName The API name of the field to check create access for.
   */
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

  /**
   * Throws a user-facing exception if the given field does not exist on the
   * object, or if the running user cannot update it.
   *
   * @param objectType The SObject type the field belongs to.
   * @param fieldApiName The API name of the field to check update access for.
   */
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
