@IsTest
private class SandboxMetadataBuilderTest {
  @IsTest
  static void buildsAutoNumberObjectNameField() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.nameFieldType = 'AutoNumber';
    objDef.nameFieldLabel = 'Deal Registration Number';
    objDef.displayFormat = 'DR-{000000}';
    objDef.startingNumber = 1;

    MetadataService.CustomObject obj = SandboxMetadataBuilder.buildObject(
      objDef
    );

    System.assertEquals('Deal_Registration__c', obj.fullName);
    System.assertEquals('Deal Registration', obj.label);
    System.assertEquals('Deal Registrations', obj.pluralLabel);
    System.assertEquals('Deployed', obj.deploymentStatus);
    System.assertEquals('ReadWrite', obj.sharingModel);
    System.assertEquals('AutoNumber', obj.nameField.type_x);
    System.assertEquals('Deal Registration Number', obj.nameField.label);
    System.assertEquals('DR-{000000}', obj.nameField.displayFormat);
    System.assertEquals(1, obj.nameField.startingNumber);
  }

  @IsTest
  static void buildsTextObjectNameFieldByDefault() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();

    MetadataService.CustomObject obj = SandboxMetadataBuilder.buildObject(
      objDef
    );

    System.assertEquals('Text', obj.nameField.type_x);
    System.assertEquals('Deal Registration Name', obj.nameField.label);
  }

  @IsTest
  static void buildsTextField() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Customer_Name__c',
      'Customer Name',
      'Text'
    );
    def.length = 120;

    MetadataService.CustomField field = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      def
    );

    System.assertEquals(
      'Deal_Registration__c.Customer_Name__c',
      field.fullName
    );
    System.assertEquals('Customer Name', field.label);
    System.assertEquals('Text', field.type_x);
    System.assertEquals(120, field.length);
  }

  @IsTest
  static void buildsLongTextAreaField() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Approval_Comments__c',
      'Approval Comments',
      'LongTextArea'
    );
    def.length = 1000;
    def.visibleLines = 8;

    MetadataService.CustomField field = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      def
    );

    System.assertEquals('LongTextArea', field.type_x);
    System.assertEquals(1000, field.length);
    System.assertEquals(8, field.visibleLines);
  }

  @IsTest
  static void buildsAutoNumberField() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Application_Number__c',
      'Application Number',
      'AutoNumber'
    );
    def.displayFormat = 'PA-{000000}';
    def.startingNumber = 1;

    MetadataService.CustomField field = SandboxMetadataBuilder.buildField(
      'Partner_Application__c',
      def
    );

    System.assertEquals('AutoNumber', field.type_x);
    System.assertEquals('PA-{000000}', field.displayFormat);
    System.assertEquals(1, field.startingNumber);
  }

  @IsTest
  static void buildsNumberAndCurrencyFields() {
    SandboxMetadataBuilder.FieldDef numberDef = fieldDef(
      'Score__c',
      'Score',
      'Number'
    );
    numberDef.precision = 10;
    numberDef.scale = 0;

    MetadataService.CustomField numberField = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      numberDef
    );

    System.assertEquals('Number', numberField.type_x);
    System.assertEquals(10, numberField.precision);
    System.assertEquals(0, numberField.scale);

    SandboxMetadataBuilder.FieldDef currencyDef = fieldDef(
      'Estimated_Amount__c',
      'Estimated Amount',
      'Currency'
    );
    currencyDef.precision = 18;
    currencyDef.scale = 2;

    MetadataService.CustomField currencyField = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      currencyDef
    );

    System.assertEquals('Currency', currencyField.type_x);
    System.assertEquals(18, currencyField.precision);
    System.assertEquals(2, currencyField.scale);
  }

  @IsTest
  static void buildsFormulaFields() {
    SandboxMetadataBuilder.FieldDef textFormulaDef = fieldDef(
      'Display_Status__c',
      'Display Status',
      'Formula'
    );
    textFormulaDef.formulaReturnType = 'Text';
    textFormulaDef.formula = 'TEXT(Status__c) & " - " & TEXT(Stage__c)';
    textFormulaDef.length = 1300;

    MetadataService.CustomField textFormulaField = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      textFormulaDef
    );

    System.assertEquals('Text', textFormulaField.type_x);
    System.assertEquals(textFormulaDef.formula, textFormulaField.formula);
    System.assertEquals(1300, textFormulaField.length);

    SandboxMetadataBuilder.FieldDef numberFormulaDef = fieldDef(
      'Protection_Days_Remaining__c',
      'Protection Days Remaining',
      'Formula'
    );
    numberFormulaDef.formulaReturnType = 'Number';
    numberFormulaDef.formula = 'Protection_End_Date__c - TODAY()';
    numberFormulaDef.precision = 18;
    numberFormulaDef.scale = 0;

    MetadataService.CustomField numberFormulaField = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      numberFormulaDef
    );

    System.assertEquals('Number', numberFormulaField.type_x);
    System.assertEquals(numberFormulaDef.formula, numberFormulaField.formula);
    System.assertEquals(18, numberFormulaField.precision);
    System.assertEquals(0, numberFormulaField.scale);
  }

  @IsTest
  static void buildsDateDateTimeCheckboxEmailPhoneUrlFields() {
    System.assertEquals(
      'Date',
      SandboxMetadataBuilder.buildField(
          'Deal_Registration__c',
          fieldDef('Close_Date__c', 'Close Date', 'Date')
        )
        .type_x
    );
    System.assertEquals(
      'DateTime',
      SandboxMetadataBuilder.buildField(
          'Deal_Registration__c',
          fieldDef('Submitted_On__c', 'Submitted On', 'DateTime')
        )
        .type_x
    );
    System.assertEquals(
      'Email',
      SandboxMetadataBuilder.buildField(
          'Deal_Registration__c',
          fieldDef('Customer_Email__c', 'Customer Email', 'Email')
        )
        .type_x
    );
    System.assertEquals(
      'Phone',
      SandboxMetadataBuilder.buildField(
          'Deal_Registration__c',
          fieldDef('Customer_Phone__c', 'Customer Phone', 'Phone')
        )
        .type_x
    );
    System.assertEquals(
      'Url',
      SandboxMetadataBuilder.buildField(
          'Deal_Registration__c',
          fieldDef('Website__c', 'Website', 'Url')
        )
        .type_x
    );

    SandboxMetadataBuilder.FieldDef checkboxDef = fieldDef(
      'Is_Protected__c',
      'Is Protected',
      'Checkbox'
    );
    checkboxDef.defaultValue = 'true';
    MetadataService.CustomField checkboxField = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      checkboxDef
    );
    System.assertEquals('Checkbox', checkboxField.type_x);
    System.assertEquals('true', checkboxField.defaultValue);
  }

  @IsTest
  static void buildsPicklistField() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Status__c',
      'Status',
      'Picklist'
    );
    def.values = new List<String>{
      'Draft',
      'Submitted',
      'Approved',
      'Rejected'
    };

    MetadataService.CustomField field = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      def
    );

    System.assertEquals('Picklist', field.type_x);
    System.assertNotEquals(null, field.valueSet);
    System.assertEquals(4, field.valueSet.valueSetDefinition.value.size());
    System.assertEquals(
      'Draft',
      field.valueSet.valueSetDefinition.value[0].fullName
    );
  }

  @IsTest
  static void buildsLookupField() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Partner_Account__c',
      'Partner Account',
      'Lookup'
    );
    def.referenceTo = 'Account';
    def.relationshipName = 'Deal_Registrations';
    def.required = true;

    MetadataService.CustomField field = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      def
    );

    System.assertEquals('Lookup', field.type_x);
    System.assertEquals('Account', field.referenceTo);
    System.assertEquals('Deal_Registrations', field.relationshipName);
    System.assertEquals('SetNull', field.deleteConstraint);
    System.assertEquals(true, field.required);
  }

  @IsTest
  static void buildsMasterDetailField() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Program__c',
      'Program',
      'MasterDetail'
    );
    def.referenceTo = 'Partner_Program__c';
    def.relationshipName = 'Deal_Registrations';
    def.relationshipLabel = 'Deal Registrations';

    MetadataService.CustomField field = SandboxMetadataBuilder.buildField(
      'Deal_Registration__c',
      def
    );

    System.assertEquals('MasterDetail', field.type_x);
    System.assertEquals('Partner_Program__c', field.referenceTo);
    System.assertEquals('Deal_Registrations', field.relationshipName);
    System.assertEquals('Deal Registrations', field.relationshipLabel);
    System.assertEquals(true, field.reparentableMasterDetail);
  }

  @IsTest
  static void buildsValidationRule() {
    SandboxMetadataBuilder.ValidationRuleDef def = validationRuleDef();

    MetadataService.ValidationRule rule = SandboxMetadataBuilder.buildValidationRule(
      'Deal_Registration__c',
      def
    );

    System.assertEquals(
      'Deal_Registration__c.Require_Customer_Name_When_Submitted',
      rule.fullName
    );
    System.assertEquals(true, rule.active);
    System.assertEquals(
      'AND(ISPICKVAL(Status__c, "Submitted"), ISBLANK(Customer_Name__c))',
      rule.errorConditionFormula
    );
    System.assertEquals('Customer_Name__c', rule.errorDisplayField);
    System.assertEquals(
      'Customer Name is required before submitting.',
      rule.errorMessage
    );
  }

  @IsTest
  static void buildsPermissionSetsForFieldPermissions() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.fieldPermissions = new List<SandboxMetadataBuilder.FieldPermissionDef>{
      fieldPermissionDef('Partner_Sync_Admin', 'Customer_Name__c', true, true),
      fieldPermissionDef('Partner_Sync_Admin', 'Status__c', true, false)
    };
    objDef.objectPermissions = new List<SandboxMetadataBuilder.ObjectPermissionDef>{
      objectPermissionDef(
        'Partner_Sync_Admin',
        null,
        true,
        true,
        true,
        false,
        true,
        false
      )
    };

    List<MetadataService.PermissionSet> permissionSets = SandboxMetadataBuilder.buildPermissionSets(
      objDef
    );

    System.assertEquals(1, permissionSets.size());
    System.assertEquals('Partner_Sync_Admin', permissionSets[0].fullName);
    System.assertEquals('Partner Sync Admin', permissionSets[0].label);
    System.assertEquals(2, permissionSets[0].fieldPermissions.size());
    System.assertEquals(
      'Deal_Registration__c.Customer_Name__c',
      permissionSets[0].fieldPermissions[0].field
    );
    System.assertEquals(true, permissionSets[0].fieldPermissions[0].readable);
    System.assertEquals(true, permissionSets[0].fieldPermissions[0].editable);
    System.assertEquals(false, permissionSets[0].fieldPermissions[1].editable);
    System.assertEquals(1, permissionSets[0].objectPermissions.size());
    System.assertEquals(
      'Deal_Registration__c',
      permissionSets[0].objectPermissions[0].object_x
    );
    System.assertEquals(true, permissionSets[0].objectPermissions[0].allowRead);
    System.assertEquals(
      true,
      permissionSets[0].objectPermissions[0].allowCreate
    );
    System.assertEquals(true, permissionSets[0].objectPermissions[0].allowEdit);
    System.assertEquals(
      false,
      permissionSets[0].objectPermissions[0].allowDelete
    );
    System.assertEquals(
      true,
      permissionSets[0].objectPermissions[0].viewAllRecords
    );
    System.assertEquals(
      false,
      permissionSets[0].objectPermissions[0].modifyAllRecords
    );
  }

  @IsTest
  static void buildsDefaultFieldPermissionsForObjectFields() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.defaultFieldPermissionSet = 'Partner_Sync_Admin';
    objDef.defaultFieldReadable = true;
    objDef.defaultFieldEditable = true;

    SandboxMetadataBuilder.FieldDef formulaDef = fieldDef(
      'Display_Status__c',
      'Display Status',
      'Formula'
    );
    formulaDef.formulaReturnType = 'Text';
    formulaDef.formula = 'TEXT(Status__c)';

    objDef.fields = new List<SandboxMetadataBuilder.FieldDef>{
      fieldDef('Customer_Name__c', 'Customer Name', 'Text'),
      fieldDef('Application_Number__c', 'Application Number', 'AutoNumber'),
      formulaDef
    };

    List<MetadataService.PermissionSet> permissionSets = SandboxMetadataBuilder.buildPermissionSets(
      objDef
    );

    System.assertEquals(1, permissionSets.size());
    System.assertEquals(3, permissionSets[0].fieldPermissions.size());

    Map<String, MetadataService.FieldPermissions> permissionsByField = new Map<String, MetadataService.FieldPermissions>();
    for (
      MetadataService.FieldPermissions permission : permissionSets[0]
        .fieldPermissions
    ) {
      permissionsByField.put(permission.field, permission);
    }

    System.assertEquals(
      true,
      permissionsByField.get('Deal_Registration__c.Customer_Name__c').editable
    );
    System.assertEquals(
      false,
      permissionsByField.get('Deal_Registration__c.Application_Number__c')
        .editable
    );
    System.assertEquals(
      false,
      permissionsByField.get('Deal_Registration__c.Display_Status__c').editable
    );
    System.assertEquals(
      true,
      permissionsByField.get('Deal_Registration__c.Display_Status__c').readable
    );
  }

  @IsTest
  static void createFromJsonCreatesObjectsFieldsValidationRulesThenFieldPermissions() {
    String jsonConfig =
      '[{' +
      '"apiName":"Deal_Registration__c",' +
      '"label":"Deal Registration",' +
      '"pluralLabel":"Deal Registrations",' +
      '"nameFieldType":"AutoNumber",' +
      '"nameFieldLabel":"Deal Registration Number",' +
      '"displayFormat":"DR-{000000}",' +
      '"startingNumber":1,' +
      '"fields":[' +
      '{"apiName":"Customer_Name__c","label":"Customer Name","type":"Text","length":255},' +
      '{"apiName":"Status__c","label":"Status","type":"Picklist","values":["Draft","Submitted","Approved"]},' +
      '{"apiName":"Partner_Account__c","label":"Partner Account","type":"Lookup","referenceTo":"Account","relationshipName":"Deal_Registrations"}' +
      '],' +
      '"validationRules":[' +
      '{"apiName":"Require_Customer_Name_When_Submitted","active":true,' +
      '"errorConditionFormula":"AND(ISPICKVAL(Status__c, \\"Submitted\\"), ISBLANK(Customer_Name__c))",' +
      '"errorDisplayField":"Customer_Name__c",' +
      '"errorMessage":"Customer Name is required before submitting."}' +
      '],' +
      '"fieldPermissions":[' +
      '{"permissionSet":"Partner_Sync_Admin","field":"Customer_Name__c","readable":true,"editable":true},' +
      '{"permissionSet":"Partner_Sync_Admin","field":"Status__c","readable":true,"editable":false}' +
      '],' +
      '"objectPermissions":[' +
      '{"permissionSet":"Partner_Sync_Admin","allowRead":true,"allowCreate":true,"allowEdit":true,"allowDelete":false,"viewAllRecords":true,"modifyAllRecords":false}' +
      ']' +
      '}]';

    MockMetadataService mockService = new MockMetadataService();

    Test.startTest();
    SandboxMetadataBuilder.createFromJson(jsonConfig, mockService);
    Test.stopTest();

    System.assertEquals(
      4,
      mockService.getBatchCount(),
      'Object, field, validation rule, and FLS batches should be separate.'
    );
    System.assertEquals(6, mockService.getTotalMetadataCount());

    MetadataService.CustomObject createdObj = mockService.getCustomObject(0, 0);
    System.assertEquals('Deal_Registration__c', createdObj.fullName);

    MetadataService.CustomField firstField = mockService.getCustomField(1, 0);
    System.assertEquals(
      'Deal_Registration__c.Customer_Name__c',
      firstField.fullName
    );

    MetadataService.ValidationRule firstRule = mockService.getValidationRule(
      2,
      0
    );
    System.assertEquals(
      'Deal_Registration__c.Require_Customer_Name_When_Submitted',
      firstRule.fullName
    );

    MetadataService.PermissionSet firstPermissionSet = mockService.getPermissionSet(
      3,
      0
    );
    System.assertEquals('Partner_Sync_Admin', firstPermissionSet.fullName);
    System.assertEquals(2, firstPermissionSet.fieldPermissions.size());
    System.assertEquals(1, firstPermissionSet.objectPermissions.size());
    System.assertEquals(
      'Deal_Registration__c',
      firstPermissionSet.objectPermissions[0].object_x
    );
  }

  @IsTest
  static void createFromJsonCreatesStandardObjectFieldsWithoutCreatingObject() {
    String jsonConfig =
      '[{' +
      '"apiName":"Lead",' +
      '"label":"Lead",' +
      '"pluralLabel":"Leads",' +
      '"skipObjectCreation":true,' +
      '"fields":[' +
      '{"apiName":"Partner_Account__c","label":"Partner Account","type":"Lookup","referenceTo":"Account","relationshipName":"Partner_Distributed_Leads"}' +
      ']' +
      '}]';

    MockMetadataService mockService = new MockMetadataService();

    Test.startTest();
    SandboxMetadataBuilder.createFromJson(jsonConfig, mockService);
    Test.stopTest();

    System.assertEquals(1, mockService.getBatchCount());
    System.assertEquals(1, mockService.getTotalMetadataCount());
    System.assertEquals(
      'Lead.Partner_Account__c',
      mockService.getCustomField(0, 0).fullName
    );
  }

  @IsTest
  static void createObjectHandlesMockErrorsWithoutException() {
    MockMetadataService mockService = new MockMetadataService();
    mockService.returnErrors = true;

    Test.startTest();
    SandboxMetadataBuilder.createObject(mockService, baseObjectDef());
    Test.stopTest();

    System.assertEquals(1, mockService.getBatchCount());
  }

  @IsTest
  static void createFieldsBatchesMetadataApiLimit() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.fields = new List<SandboxMetadataBuilder.FieldDef>();

    for (Integer index = 1; index <= 11; index++) {
      objDef.fields.add(
        fieldDef(
          'Generated_Field_' + index + '__c',
          'Generated Field ' + index,
          'Text'
        )
      );
    }

    MockMetadataService mockService = new MockMetadataService();

    Test.startTest();
    SandboxMetadataBuilder.createFields(mockService, objDef);
    Test.stopTest();

    System.assertEquals(2, mockService.getBatchCount());
    System.assertEquals(10, mockService.capturedBatches[0].size());
    System.assertEquals(1, mockService.capturedBatches[1].size());
    System.assertEquals(11, mockService.getTotalMetadataCount());
  }

  @IsTest
  static void createFieldsCreatesFormulaFieldsAfterStandardFields() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    SandboxMetadataBuilder.FieldDef formulaDef = fieldDef(
      'Display_Status__c',
      'Display Status',
      'Formula'
    );
    formulaDef.formulaReturnType = 'Text';
    formulaDef.formula = 'TEXT(Status__c)';

    objDef.fields = new List<SandboxMetadataBuilder.FieldDef>{
      formulaDef,
      fieldDef('Status__c', 'Status', 'Text')
    };

    MockMetadataService mockService = new MockMetadataService();

    Test.startTest();
    SandboxMetadataBuilder.createFields(mockService, objDef);
    Test.stopTest();

    System.assertEquals(2, mockService.getBatchCount());

    MetadataService.CustomField standardField = mockService.getCustomField(
      0,
      0
    );
    MetadataService.CustomField formulaField = mockService.getCustomField(1, 0);

    System.assertEquals(
      'Deal_Registration__c.Status__c',
      standardField.fullName
    );
    System.assertEquals(
      'Deal_Registration__c.Display_Status__c',
      formulaField.fullName
    );
    System.assertEquals('TEXT(Status__c)', formulaField.formula);
  }

  @IsTest
  static void mockMetadataServiceSupportsTargetedFailures() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.fields = new List<SandboxMetadataBuilder.FieldDef>{
      fieldDef('First_Field__c', 'First Field', 'Text'),
      fieldDef('Second_Field__c', 'Second Field', 'Text')
    };

    MockMetadataService mockService = new MockMetadataService();
    mockService.failingFullNames.add('Deal_Registration__c.Second_Field__c');

    Test.startTest();
    SandboxMetadataBuilder.createFields(mockService, objDef);
    Test.stopTest();

    System.assertEquals(1, mockService.getBatchCount());
    System.assertEquals(1, mockService.capturedResults.size());
    System.assertEquals(true, mockService.getSaveResult(0, 0).success);
    System.assertEquals(false, mockService.getSaveResult(0, 1).success);
    System.assertEquals(
      'MOCK_METADATA_FAILURE',
      mockService.getSaveResult(0, 1).errors[0].statusCode
    );
  }

  @IsTest
  static void throwsForInvalidObjectApiName() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.apiName = 'DealRegistration';

    try {
      SandboxMetadataBuilder.buildObject(objDef);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('skipObjectCreation is true'));
    }
  }

  @IsTest
  static void throwsForUnsupportedFieldType() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Bad_Field__c',
      'Bad Field',
      'UnsupportedType'
    );

    try {
      SandboxMetadataBuilder.buildField('Deal_Registration__c', def);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('Unsupported field type'));
    }
  }

  @IsTest
  static void throwsForPicklistWithoutValues() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Status__c',
      'Status',
      'Picklist'
    );

    try {
      SandboxMetadataBuilder.buildField('Deal_Registration__c', def);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('Picklist field requires'));
    }
  }

  @IsTest
  static void throwsForFormulaWithoutFormula() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Bad_Formula__c',
      'Bad Formula',
      'Formula'
    );
    def.formulaReturnType = 'Text';

    try {
      SandboxMetadataBuilder.buildField('Deal_Registration__c', def);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('requires formula'));
    }
  }

  @IsTest
  static void throwsForUnsupportedFormulaReturnType() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Bad_Formula__c',
      'Bad Formula',
      'Formula'
    );
    def.formula = 'Name';
    def.formulaReturnType = 'Picklist';

    try {
      SandboxMetadataBuilder.buildField('Deal_Registration__c', def);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('Unsupported formulaReturnType'));
    }
  }

  @IsTest
  static void throwsForLookupWithoutReferenceTo() {
    SandboxMetadataBuilder.FieldDef def = fieldDef(
      'Partner_Account__c',
      'Partner Account',
      'Lookup'
    );
    def.relationshipName = 'Deal_Registrations';

    try {
      SandboxMetadataBuilder.buildField('Deal_Registration__c', def);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('requires referenceTo'));
    }
  }

  @IsTest
  static void throwsForValidationRuleWithoutFormula() {
    SandboxMetadataBuilder.ValidationRuleDef def = validationRuleDef();
    def.errorConditionFormula = null;

    try {
      SandboxMetadataBuilder.buildValidationRule('Deal_Registration__c', def);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(
        ex.getMessage().contains('errorConditionFormula is required')
      );
    }
  }

  @IsTest
  static void throwsForFieldPermissionWithoutPermissionSet() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.fieldPermissions = new List<SandboxMetadataBuilder.FieldPermissionDef>{
      fieldPermissionDef(null, 'Customer_Name__c', true, true)
    };

    try {
      SandboxMetadataBuilder.buildPermissionSets(objDef);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('permissionSet is required'));
    }
  }

  @IsTest
  static void throwsForObjectPermissionWithoutPermissionSet() {
    SandboxMetadataBuilder.ObjectDef objDef = baseObjectDef();
    objDef.objectPermissions = new List<SandboxMetadataBuilder.ObjectPermissionDef>{
      objectPermissionDef(null, null, true, true, true, false, false, false)
    };

    try {
      SandboxMetadataBuilder.buildPermissionSets(objDef);
      System.assert(false, 'Expected MetadataBuilderException.');
    } catch (SandboxMetadataBuilder.MetadataBuilderException ex) {
      System.assert(ex.getMessage().contains('permissionSet is required'));
    }
  }

  private static SandboxMetadataBuilder.ObjectDef baseObjectDef() {
    SandboxMetadataBuilder.ObjectDef objDef = new SandboxMetadataBuilder.ObjectDef();
    objDef.apiName = 'Deal_Registration__c';
    objDef.label = 'Deal Registration';
    objDef.pluralLabel = 'Deal Registrations';
    return objDef;
  }

  private static SandboxMetadataBuilder.FieldDef fieldDef(
    String apiName,
    String label,
    String typeName
  ) {
    SandboxMetadataBuilder.FieldDef def = new SandboxMetadataBuilder.FieldDef();
    def.apiName = apiName;
    def.label = label;
    def.type = typeName;
    return def;
  }

  private static SandboxMetadataBuilder.ValidationRuleDef validationRuleDef() {
    SandboxMetadataBuilder.ValidationRuleDef def = new SandboxMetadataBuilder.ValidationRuleDef();
    def.apiName = 'Require_Customer_Name_When_Submitted';
    def.active = true;
    def.errorConditionFormula = 'AND(ISPICKVAL(Status__c, "Submitted"), ISBLANK(Customer_Name__c))';
    def.errorDisplayField = 'Customer_Name__c';
    def.errorMessage = 'Customer Name is required before submitting.';
    return def;
  }

  private static SandboxMetadataBuilder.FieldPermissionDef fieldPermissionDef(
    String permissionSet,
    String field,
    Boolean readable,
    Boolean editable
  ) {
    SandboxMetadataBuilder.FieldPermissionDef def = new SandboxMetadataBuilder.FieldPermissionDef();
    def.permissionSet = permissionSet;
    def.field = field;
    def.readable = readable;
    def.editable = editable;
    return def;
  }

  private static SandboxMetadataBuilder.ObjectPermissionDef objectPermissionDef(
    String permissionSet,
    String objectApiName,
    Boolean allowRead,
    Boolean allowCreate,
    Boolean allowEdit,
    Boolean allowDelete,
    Boolean viewAllRecords,
    Boolean modifyAllRecords
  ) {
    SandboxMetadataBuilder.ObjectPermissionDef def = new SandboxMetadataBuilder.ObjectPermissionDef();
    def.permissionSet = permissionSet;
    def.objectApiName = objectApiName;
    def.allowRead = allowRead;
    def.allowCreate = allowCreate;
    def.allowEdit = allowEdit;
    def.allowDelete = allowDelete;
    def.viewAllRecords = viewAllRecords;
    def.modifyAllRecords = modifyAllRecords;
    return def;
  }
}
