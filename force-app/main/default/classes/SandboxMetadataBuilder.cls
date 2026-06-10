public with sharing class SandboxMetadataBuilder {
  private static Integer CREATE_METADATA_BATCH_SIZE = 10;

  public interface IMetadataService {
    MetadataService.SaveResult[] createMetadata(
      MetadataService.Metadata[] metadataItems
    );
  }

  public class MetadataServiceImpl implements IMetadataService {
    private MetadataService.MetadataPort service;

    public MetadataServiceImpl() {
      service = new MetadataService.MetadataPort();
      service.SessionHeader = new MetadataService.SessionHeader_element();
      service.SessionHeader.sessionId = UserInfo.getSessionId();
    }

    public MetadataService.SaveResult[] createMetadata(
      MetadataService.Metadata[] metadataItems
    ) {
      return service.createMetadata(metadataItems);
    }
  }

  public class ObjectDef {
    public String apiName;
    public String label;
    public String pluralLabel;
    public String sharingModel;
    public Boolean skipObjectCreation;
    public String defaultFieldPermissionSet;
    public Boolean defaultFieldReadable;
    public Boolean defaultFieldEditable;

    // Name field configuration. Supported values: Text, AutoNumber.
    public String nameFieldType;
    public String nameFieldLabel;
    public String displayFormat;
    public Integer startingNumber;

    public List<FieldDef> fields;
    public List<ValidationRuleDef> validationRules;
    public List<FieldPermissionDef> fieldPermissions;
    public List<ObjectPermissionDef> objectPermissions;
  }

  public class FieldDef {
    public String apiName;
    public String label;
    public String type;

    public Integer length;
    public Integer precision;
    public Integer scale;
    public Integer visibleLines;

    public Boolean required;
    public Boolean unique;
    public Boolean externalId;

    public String defaultValue;
    public String displayFormat;
    public Integer startingNumber;

    public String referenceTo;
    public String relationshipName;
    public String relationshipLabel;

    public String description;
    public String inlineHelpText;
    public String formula;
    public String formulaReturnType;

    public List<String> values;
  }

  public class ValidationRuleDef {
    public String apiName;
    public String fullName;
    public Boolean active;
    public String description;
    public String errorConditionFormula;
    public String errorDisplayField;
    public String errorMessage;
  }

  public class FieldPermissionDef {
    public String permissionSet;
    public String field;
    public Boolean readable;
    public Boolean editable;
  }

  public class ObjectPermissionDef {
    public String permissionSet;
    public String objectApiName;
    public Boolean allowRead;
    public Boolean allowCreate;
    public Boolean allowEdit;
    public Boolean allowDelete;
    public Boolean viewAllRecords;
    public Boolean modifyAllRecords;
  }

  public static void createFromJson(String jsonConfig) {
    createFromJson(jsonConfig, new MetadataServiceImpl());
  }

  @TestVisible
  static void createFromJson(
    String jsonConfig,
    IMetadataService metadataService
  ) {
    if (String.isBlank(jsonConfig)) {
      throw new MetadataBuilderException('JSON configuration is required.');
    }
    if (metadataService == null) {
      throw new MetadataBuilderException('Metadata service is required.');
    }

    List<ObjectDef> objectDefs = (List<ObjectDef>) JSON.deserialize(
      jsonConfig,
      List<ObjectDef>.class
    );

    if (objectDefs == null || objectDefs.isEmpty()) {
      throw new MetadataBuilderException(
        'At least one object definition is required.'
      );
    }

    // Phase 1: create objects first.
    for (ObjectDef objDef : objectDefs) {
      if (!shouldSkipObjectCreation(objDef)) {
        createObject(metadataService, objDef);
      }
    }

    // Phase 2: create fields after objects exist.
    for (ObjectDef objDef : objectDefs) {
      if (objDef.fields != null && !objDef.fields.isEmpty()) {
        createFields(metadataService, objDef);
      }
    }

    // Phase 3: create validation rules after fields exist.
    for (ObjectDef objDef : objectDefs) {
      if (objDef.validationRules != null && !objDef.validationRules.isEmpty()) {
        createValidationRules(metadataService, objDef);
      }
    }

    // Phase 4: create permission sets after fields exist.
    for (ObjectDef objDef : objectDefs) {
      if (
        hasDefaultFieldPermissions(objDef) ||
        hasFieldPermissions(objDef) ||
        hasObjectPermissions(objDef)
      ) {
        createFieldPermissions(metadataService, objDef);
      }
    }
  }

  @TestVisible
  static void createObject(IMetadataService metadataService, ObjectDef objDef) {
    if (shouldSkipObjectCreation(objDef)) {
      return;
    }

    MetadataService.CustomObject obj = buildObject(objDef);

    MetadataService.SaveResult[] results = metadataService.createMetadata(
      new List<MetadataService.Metadata>{ obj }
    );

    handleResults(results, 'Object: ' + objDef.apiName);
  }

  @TestVisible
  static void createFields(IMetadataService metadataService, ObjectDef objDef) {
    validateObjectDef(objDef);

    List<MetadataService.Metadata> standardFields = new List<MetadataService.Metadata>();
    List<MetadataService.Metadata> formulaFields = new List<MetadataService.Metadata>();

    for (FieldDef fieldDef : objDef.fields) {
      MetadataService.CustomField field = buildField(objDef.apiName, fieldDef);
      if (fieldDef.type == 'Formula') {
        formulaFields.add(field);
      } else {
        standardFields.add(field);
      }
    }

    createMetadataInBatches(
      metadataService,
      standardFields,
      'Fields for: ' + objDef.apiName
    );
    createMetadataInBatches(
      metadataService,
      formulaFields,
      'Formula fields for: ' + objDef.apiName
    );
  }

  @TestVisible
  static void createValidationRules(
    IMetadataService metadataService,
    ObjectDef objDef
  ) {
    validateObjectDef(objDef);

    List<MetadataService.Metadata> metadataItems = new List<MetadataService.Metadata>();

    for (ValidationRuleDef ruleDef : objDef.validationRules) {
      metadataItems.add(buildValidationRule(objDef.apiName, ruleDef));
    }

    createMetadataInBatches(
      metadataService,
      metadataItems,
      'Validation rules for: ' + objDef.apiName
    );
  }

  @TestVisible
  static void createFieldPermissions(
    IMetadataService metadataService,
    ObjectDef objDef
  ) {
    validateObjectDef(objDef);

    List<MetadataService.Metadata> metadataItems = new List<MetadataService.Metadata>();

    for (
      MetadataService.PermissionSet permissionSet : buildPermissionSets(objDef)
    ) {
      metadataItems.add(permissionSet);
    }

    createMetadataInBatches(
      metadataService,
      metadataItems,
      'Field permissions for: ' + objDef.apiName
    );
  }

  @TestVisible
  static MetadataService.CustomObject buildObject(ObjectDef objDef) {
    validateObjectDef(objDef);

    MetadataService.CustomObject obj = new MetadataService.CustomObject();

    obj.fullName = objDef.apiName;
    obj.label = objDef.label;
    obj.pluralLabel = String.isBlank(objDef.pluralLabel)
      ? objDef.label + 's'
      : objDef.pluralLabel;
    obj.deploymentStatus = 'Deployed';
    obj.sharingModel = String.isBlank(objDef.sharingModel)
      ? 'ReadWrite'
      : objDef.sharingModel;

    obj.nameField = new MetadataService.CustomField();

    String nameType = String.isBlank(objDef.nameFieldType)
      ? 'Text'
      : objDef.nameFieldType;

    obj.nameField.label = String.isBlank(objDef.nameFieldLabel)
      ? objDef.label + ' Name'
      : objDef.nameFieldLabel;

    if (nameType == 'AutoNumber') {
      obj.nameField.type_x = 'AutoNumber';
      obj.nameField.displayFormat = String.isBlank(objDef.displayFormat)
        ? 'AUTO-{000000}'
        : objDef.displayFormat;
      obj.nameField.startingNumber = objDef.startingNumber == null
        ? 1
        : objDef.startingNumber;
    } else if (nameType == 'Text') {
      obj.nameField.type_x = 'Text';
    } else {
      throw new MetadataBuilderException(
        'Unsupported nameFieldType: ' + nameType
      );
    }

    return obj;
  }

  @TestVisible
  static MetadataService.CustomField buildField(
    String objectApiName,
    FieldDef fieldDef
  ) {
    validateFieldDef(objectApiName, fieldDef);

    MetadataService.CustomField field = new MetadataService.CustomField();

    field.fullName = objectApiName + '.' + fieldDef.apiName;
    field.label = fieldDef.label;
    field.description = fieldDef.description;
    field.inlineHelpText = fieldDef.inlineHelpText;

    String fieldType = fieldDef.type;

    if (fieldType == 'Text') {
      field.type_x = 'Text';
      field.length = fieldDef.length == null ? 255 : fieldDef.length;
    } else if (fieldType == 'LongTextArea') {
      field.type_x = 'LongTextArea';
      field.length = fieldDef.length == null ? 32768 : fieldDef.length;
      field.visibleLines = fieldDef.visibleLines == null
        ? 5
        : fieldDef.visibleLines;
    } else if (fieldType == 'AutoNumber') {
      field.type_x = 'AutoNumber';
      field.displayFormat = String.isBlank(fieldDef.displayFormat)
        ? 'AUTO-{000000}'
        : fieldDef.displayFormat;
      field.startingNumber = fieldDef.startingNumber == null
        ? 1
        : fieldDef.startingNumber;
    } else if (fieldType == 'Number') {
      field.type_x = 'Number';
      field.precision = fieldDef.precision == null ? 18 : fieldDef.precision;
      field.scale = fieldDef.scale == null ? 0 : fieldDef.scale;
    } else if (fieldType == 'Currency') {
      field.type_x = 'Currency';
      field.precision = fieldDef.precision == null ? 18 : fieldDef.precision;
      field.scale = fieldDef.scale == null ? 2 : fieldDef.scale;
    } else if (fieldType == 'Percent') {
      field.type_x = 'Percent';
      field.precision = fieldDef.precision == null ? 18 : fieldDef.precision;
      field.scale = fieldDef.scale == null ? 2 : fieldDef.scale;
    } else if (fieldType == 'Formula') {
      field.type_x = fieldDef.formulaReturnType;
      field.formula = fieldDef.formula;
      applyFormulaReturnTypeSettings(field, fieldDef);
    } else if (fieldType == 'Date') {
      field.type_x = 'Date';
    } else if (fieldType == 'DateTime') {
      field.type_x = 'DateTime';
    } else if (fieldType == 'Checkbox') {
      field.type_x = 'Checkbox';
      field.defaultValue = String.isBlank(fieldDef.defaultValue)
        ? 'false'
        : fieldDef.defaultValue;
    } else if (fieldType == 'Email') {
      field.type_x = 'Email';
    } else if (fieldType == 'Phone') {
      field.type_x = 'Phone';
    } else if (fieldType == 'Url') {
      field.type_x = 'Url';
    } else if (fieldType == 'Picklist') {
      field.type_x = 'Picklist';
      field.valueSet = buildPicklistValueSet(fieldDef.values);
    } else if (fieldType == 'Lookup') {
      field.type_x = 'Lookup';
      field.referenceTo = fieldDef.referenceTo;
      field.relationshipName = fieldDef.relationshipName;
      field.deleteConstraint = 'SetNull';
    } else if (fieldType == 'MasterDetail') {
      field.type_x = 'MasterDetail';
      field.referenceTo = fieldDef.referenceTo;
      field.relationshipName = fieldDef.relationshipName;
      field.relationshipLabel = String.isBlank(fieldDef.relationshipLabel)
        ? fieldDef.label
        : fieldDef.relationshipLabel;
      field.reparentableMasterDetail = true;
    } else {
      throw new MetadataBuilderException(
        'Unsupported field type: ' + fieldType
      );
    }

    field.required = fieldDef.required == true;
    field.unique = fieldDef.unique == true;
    field.externalId = fieldDef.externalId == true;

    return field;
  }

  private static void applyFormulaReturnTypeSettings(
    MetadataService.CustomField field,
    FieldDef fieldDef
  ) {
    String returnType = fieldDef.formulaReturnType;

    if (returnType == 'Text') {
      field.length = fieldDef.length == null ? 255 : fieldDef.length;
    } else if (returnType == 'Number') {
      field.precision = fieldDef.precision == null ? 18 : fieldDef.precision;
      field.scale = fieldDef.scale == null ? 0 : fieldDef.scale;
    } else if (returnType == 'Currency' || returnType == 'Percent') {
      field.precision = fieldDef.precision == null ? 18 : fieldDef.precision;
      field.scale = fieldDef.scale == null ? 2 : fieldDef.scale;
    }
  }

  @TestVisible
  static MetadataService.ValidationRule buildValidationRule(
    String objectApiName,
    ValidationRuleDef ruleDef
  ) {
    validateValidationRuleDef(objectApiName, ruleDef);

    MetadataService.ValidationRule rule = new MetadataService.ValidationRule();

    String ruleName = String.isBlank(ruleDef.fullName)
      ? ruleDef.apiName
      : ruleDef.fullName;

    rule.fullName = ruleName.contains('.')
      ? ruleName
      : objectApiName + '.' + ruleName;
    rule.active = ruleDef.active == null ? true : ruleDef.active;
    rule.description = ruleDef.description;
    rule.errorConditionFormula = ruleDef.errorConditionFormula;
    rule.errorDisplayField = ruleDef.errorDisplayField;
    rule.errorMessage = ruleDef.errorMessage;

    return rule;
  }

  @TestVisible
  static List<MetadataService.PermissionSet> buildPermissionSets(
    ObjectDef objDef
  ) {
    validateObjectDef(objDef);

    Map<String, Map<String, MetadataService.FieldPermissions>> fieldPermissionsBySet = new Map<String, Map<String, MetadataService.FieldPermissions>>();
    Map<String, List<MetadataService.ObjectPermissions>> objectPermissionsBySet = new Map<String, List<MetadataService.ObjectPermissions>>();

    if (hasDefaultFieldPermissions(objDef)) {
      for (FieldDef fieldDef : objDef.fields) {
        MetadataService.FieldPermissions permission = buildDefaultFieldPermission(
          objDef,
          fieldDef
        );
        addFieldPermission(
          fieldPermissionsBySet,
          objDef.defaultFieldPermissionSet,
          permission
        );
      }
    }

    if (hasFieldPermissions(objDef)) {
      for (FieldPermissionDef permissionDef : objDef.fieldPermissions) {
        validateFieldPermissionDef(objDef.apiName, permissionDef);

        MetadataService.FieldPermissions permission = buildFieldPermission(
          objDef.apiName,
          permissionDef
        );
        addFieldPermission(
          fieldPermissionsBySet,
          permissionDef.permissionSet,
          permission
        );
      }
    }

    if (hasObjectPermissions(objDef)) {
      for (ObjectPermissionDef permissionDef : objDef.objectPermissions) {
        validateObjectPermissionDef(objDef.apiName, permissionDef);

        if (!objectPermissionsBySet.containsKey(permissionDef.permissionSet)) {
          objectPermissionsBySet.put(
            permissionDef.permissionSet,
            new List<MetadataService.ObjectPermissions>()
          );
        }

        objectPermissionsBySet.get(permissionDef.permissionSet)
          .add(buildObjectPermission(objDef.apiName, permissionDef));
      }
    }

    List<MetadataService.PermissionSet> permissionSets = new List<MetadataService.PermissionSet>();

    Set<String> permissionSetNames = new Set<String>();
    permissionSetNames.addAll(fieldPermissionsBySet.keySet());
    permissionSetNames.addAll(objectPermissionsBySet.keySet());

    for (String permissionSetName : permissionSetNames) {
      MetadataService.PermissionSet permissionSet = new MetadataService.PermissionSet();
      permissionSet.fullName = permissionSetName;
      permissionSet.label = permissionSetName.replace('_', ' ');
      if (fieldPermissionsBySet.containsKey(permissionSetName)) {
        permissionSet.fieldPermissions = fieldPermissionsBySet.get(
            permissionSetName
          )
          .values();
      }
      if (objectPermissionsBySet.containsKey(permissionSetName)) {
        permissionSet.objectPermissions = objectPermissionsBySet.get(
          permissionSetName
        );
      }
      permissionSets.add(permissionSet);
    }

    return permissionSets;
  }

  private static void addFieldPermission(
    Map<String, Map<String, MetadataService.FieldPermissions>> fieldPermissionsBySet,
    String permissionSetName,
    MetadataService.FieldPermissions permission
  ) {
    if (!fieldPermissionsBySet.containsKey(permissionSetName)) {
      fieldPermissionsBySet.put(
        permissionSetName,
        new Map<String, MetadataService.FieldPermissions>()
      );
    }

    fieldPermissionsBySet.get(permissionSetName)
      .put(permission.field, permission);
  }

  private static MetadataService.FieldPermissions buildDefaultFieldPermission(
    ObjectDef objDef,
    FieldDef fieldDef
  ) {
    MetadataService.FieldPermissions permission = new MetadataService.FieldPermissions();
    permission.field = objDef.apiName + '.' + fieldDef.apiName;
    permission.editable =
      objDef.defaultFieldEditable == true && !isReadOnlyField(fieldDef);
    permission.readable =
      permission.editable || objDef.defaultFieldReadable != false;
    return permission;
  }

  private static Boolean isReadOnlyField(FieldDef fieldDef) {
    return fieldDef != null &&
      (fieldDef.type == 'Formula' ||
      fieldDef.type == 'AutoNumber');
  }

  private static MetadataService.FieldPermissions buildFieldPermission(
    String objectApiName,
    FieldPermissionDef permissionDef
  ) {
    MetadataService.FieldPermissions permission = new MetadataService.FieldPermissions();
    permission.field = permissionDef.field.contains('.')
      ? permissionDef.field
      : objectApiName + '.' + permissionDef.field;
    permission.editable = permissionDef.editable == true;
    permission.readable = permission.editable || permissionDef.readable == true;
    return permission;
  }

  private static MetadataService.ObjectPermissions buildObjectPermission(
    String objectApiName,
    ObjectPermissionDef permissionDef
  ) {
    MetadataService.ObjectPermissions permission = new MetadataService.ObjectPermissions();
    permission.object_x = String.isBlank(permissionDef.objectApiName)
      ? objectApiName
      : permissionDef.objectApiName;
    permission.allowCreate = permissionDef.allowCreate == true;
    permission.allowDelete = permissionDef.allowDelete == true;
    permission.allowEdit =
      permissionDef.allowEdit == true ||
      permission.allowDelete == true;
    permission.allowRead =
      permissionDef.allowRead == true ||
      permission.allowCreate == true ||
      permission.allowEdit == true ||
      permission.allowDelete == true ||
      permissionDef.viewAllRecords == true ||
      permissionDef.modifyAllRecords == true;
    permission.viewAllRecords =
      permissionDef.viewAllRecords == true ||
      permissionDef.modifyAllRecords == true;
    permission.modifyAllRecords = permissionDef.modifyAllRecords == true;
    return permission;
  }

  private static MetadataService.ValueSet buildPicklistValueSet(
    List<String> values
  ) {
    if (values == null || values.isEmpty()) {
      throw new MetadataBuilderException(
        'Picklist field requires at least one value.'
      );
    }

    MetadataService.ValueSet valueSet = new MetadataService.ValueSet();
    MetadataService.ValueSetValuesDefinition valueDef = new MetadataService.ValueSetValuesDefinition();

    valueDef.sorted = false;
    valueDef.value = new List<MetadataService.CustomValue>();

    for (String valueName : values) {
      if (String.isBlank(valueName)) {
        continue;
      }

      MetadataService.CustomValue customValue = new MetadataService.CustomValue();
      customValue.fullName = valueName;
      customValue.label = valueName;
      customValue.default_x = false;

      valueDef.value.add(customValue);
    }

    if (valueDef.value.isEmpty()) {
      throw new MetadataBuilderException(
        'Picklist field requires at least one non-blank value.'
      );
    }

    valueSet.valueSetDefinition = valueDef;
    return valueSet;
  }

  private static void validateObjectDef(ObjectDef objDef) {
    if (objDef == null) {
      throw new MetadataBuilderException('Object definition cannot be null.');
    }
    if (String.isBlank(objDef.apiName)) {
      throw new MetadataBuilderException('Object apiName is required.');
    }
    if (String.isBlank(objDef.label)) {
      throw new MetadataBuilderException(
        'Object label is required for ' + objDef.apiName
      );
    }
    if (!isCustomObjectDef(objDef) && !shouldSkipObjectCreation(objDef)) {
      throw new MetadataBuilderException(
        'Object API name should end with __c or __mdt unless skipObjectCreation is true: ' +
        objDef.apiName
      );
    }
  }

  private static Boolean isCustomObjectDef(ObjectDef objDef) {
    return objDef != null &&
      !String.isBlank(objDef.apiName) &&
      (objDef.apiName.endsWith('__c') || objDef.apiName.endsWith('__mdt'));
  }

  private static Boolean shouldSkipObjectCreation(ObjectDef objDef) {
    return objDef != null && objDef.skipObjectCreation == true;
  }

  private static void validateFieldDef(
    String objectApiName,
    FieldDef fieldDef
  ) {
    if (String.isBlank(objectApiName)) {
      throw new MetadataBuilderException('Parent object API name is required.');
    }
    if (fieldDef == null) {
      throw new MetadataBuilderException('Field definition cannot be null.');
    }
    if (String.isBlank(fieldDef.apiName)) {
      throw new MetadataBuilderException(
        'Field apiName is required for object ' + objectApiName
      );
    }
    if (String.isBlank(fieldDef.label)) {
      throw new MetadataBuilderException(
        'Field label is required for ' + fieldDef.apiName
      );
    }
    if (String.isBlank(fieldDef.type)) {
      throw new MetadataBuilderException(
        'Field type is required for ' + fieldDef.apiName
      );
    }
    if (!fieldDef.apiName.endsWith('__c')) {
      throw new MetadataBuilderException(
        'Custom field API name should end with __c: ' + fieldDef.apiName
      );
    }
    if (fieldDef.type == 'Lookup' || fieldDef.type == 'MasterDetail') {
      if (String.isBlank(fieldDef.referenceTo)) {
        throw new MetadataBuilderException(
          fieldDef.type + ' field requires referenceTo: ' + fieldDef.apiName
        );
      }
      if (String.isBlank(fieldDef.relationshipName)) {
        throw new MetadataBuilderException(
          fieldDef.type +
            ' field requires relationshipName: ' +
            fieldDef.apiName
        );
      }
    }
    if (fieldDef.type == 'Formula') {
      validateFormulaFieldDef(fieldDef);
    }
  }

  private static void validateFormulaFieldDef(FieldDef fieldDef) {
    if (String.isBlank(fieldDef.formula)) {
      throw new MetadataBuilderException(
        'Formula field requires formula: ' + fieldDef.apiName
      );
    }
    if (String.isBlank(fieldDef.formulaReturnType)) {
      throw new MetadataBuilderException(
        'Formula field requires formulaReturnType: ' + fieldDef.apiName
      );
    }

    Set<String> supportedReturnTypes = new Set<String>{
      'Checkbox',
      'Currency',
      'Date',
      'DateTime',
      'Number',
      'Percent',
      'Text'
    };

    if (!supportedReturnTypes.contains(fieldDef.formulaReturnType)) {
      throw new MetadataBuilderException(
        'Unsupported formulaReturnType: ' +
          fieldDef.formulaReturnType +
          ' for ' +
          fieldDef.apiName
      );
    }
  }

  private static void validateValidationRuleDef(
    String objectApiName,
    ValidationRuleDef ruleDef
  ) {
    if (String.isBlank(objectApiName)) {
      throw new MetadataBuilderException('Parent object API name is required.');
    }
    if (ruleDef == null) {
      throw new MetadataBuilderException(
        'Validation rule definition cannot be null.'
      );
    }
    if (String.isBlank(ruleDef.apiName) && String.isBlank(ruleDef.fullName)) {
      throw new MetadataBuilderException(
        'Validation rule apiName or fullName is required for object ' +
        objectApiName
      );
    }
    if (String.isBlank(ruleDef.errorConditionFormula)) {
      throw new MetadataBuilderException(
        'Validation rule errorConditionFormula is required for ' +
        getValidationRuleName(ruleDef)
      );
    }
    if (String.isBlank(ruleDef.errorMessage)) {
      throw new MetadataBuilderException(
        'Validation rule errorMessage is required for ' +
        getValidationRuleName(ruleDef)
      );
    }
  }

  private static String getValidationRuleName(ValidationRuleDef ruleDef) {
    return String.isBlank(ruleDef.apiName) ? ruleDef.fullName : ruleDef.apiName;
  }

  private static void validateFieldPermissionDef(
    String objectApiName,
    FieldPermissionDef permissionDef
  ) {
    if (String.isBlank(objectApiName)) {
      throw new MetadataBuilderException('Parent object API name is required.');
    }
    if (permissionDef == null) {
      throw new MetadataBuilderException(
        'Field permission definition cannot be null.'
      );
    }
    if (String.isBlank(permissionDef.permissionSet)) {
      throw new MetadataBuilderException(
        'Field permission permissionSet is required for object ' + objectApiName
      );
    }
    if (String.isBlank(permissionDef.field)) {
      throw new MetadataBuilderException(
        'Field permission field is required for permission set ' +
        permissionDef.permissionSet
      );
    }
  }

  private static void validateObjectPermissionDef(
    String objectApiName,
    ObjectPermissionDef permissionDef
  ) {
    if (String.isBlank(objectApiName)) {
      throw new MetadataBuilderException('Parent object API name is required.');
    }
    if (permissionDef == null) {
      throw new MetadataBuilderException(
        'Object permission definition cannot be null.'
      );
    }
    if (String.isBlank(permissionDef.permissionSet)) {
      throw new MetadataBuilderException(
        'Object permission permissionSet is required for object ' +
        objectApiName
      );
    }
  }

  private static Boolean hasFieldPermissions(ObjectDef objDef) {
    return objDef.fieldPermissions != null &&
      !objDef.fieldPermissions.isEmpty();
  }

  private static Boolean hasDefaultFieldPermissions(ObjectDef objDef) {
    return objDef != null &&
      !String.isBlank(objDef.defaultFieldPermissionSet) &&
      objDef.fields != null &&
      !objDef.fields.isEmpty();
  }

  private static Boolean hasObjectPermissions(ObjectDef objDef) {
    return objDef.objectPermissions != null &&
      !objDef.objectPermissions.isEmpty();
  }

  private static void createMetadataInBatches(
    IMetadataService metadataService,
    List<MetadataService.Metadata> metadataItems,
    String context
  ) {
    if (metadataItems == null || metadataItems.isEmpty()) {
      return;
    }

    for (
      Integer startIndex = 0;
      startIndex < metadataItems.size();
      startIndex += CREATE_METADATA_BATCH_SIZE
    ) {
      List<MetadataService.Metadata> batch = new List<MetadataService.Metadata>();
      Integer endIndex = startIndex + CREATE_METADATA_BATCH_SIZE;
      if (endIndex > metadataItems.size()) {
        endIndex = metadataItems.size();
      }

      for (Integer itemIndex = startIndex; itemIndex < endIndex; itemIndex++) {
        batch.add(metadataItems[itemIndex]);
      }

      MetadataService.SaveResult[] results = metadataService.createMetadata(
        batch
      );

      handleResults(
        results,
        context + ' batch ' + ((startIndex / CREATE_METADATA_BATCH_SIZE) + 1)
      );
    }
  }

  private static void handleResults(
    MetadataService.SaveResult[] results,
    String context
  ) {
    if (results == null) {
      System.debug(
        LoggingLevel.ERROR,
        context + ' returned no Metadata API result.'
      );
      return;
    }

    for (MetadataService.SaveResult result : results) {
      if (result == null) {
        continue;
      }
      if (result.success) {
        System.debug(LoggingLevel.INFO, context + ' created successfully.');
      } else if (result.errors != null) {
        for (MetadataService.Error err : result.errors) {
          System.debug(LoggingLevel.ERROR, context + ' failed: ' + err.message);
        }
      }
    }
  }

  public class MetadataBuilderException extends Exception {
  }
}
