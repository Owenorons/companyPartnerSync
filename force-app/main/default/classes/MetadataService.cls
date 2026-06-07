public class MetadataService {
  private static String SOAP_M_URI = 'http://soap.sforce.com/2006/04/metadata';

  public virtual class Metadata {
    public String fullName;
  }

  public class MetadataPort {
    public String endpoint_x =
      URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/63.0';
    public Map<String, String> inputHttpHeaders_x;
    public Map<String, String> outputHttpHeaders_x;
    public String clientCertName_x;
    public String clientCert_x;
    public String clientCertPasswd_x;
    public Integer timeout_x;
    public MetadataService.SessionHeader_element SessionHeader;
    public MetadataService.CallOptions_element CallOptions;
    public MetadataService.AllOrNoneHeader_element AllOrNoneHeader;
    private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
    private String CallOptions_hns = 'CallOptions=http://soap.sforce.com/2006/04/metadata';
    private String AllOrNoneHeader_hns = 'AllOrNoneHeader=http://soap.sforce.com/2006/04/metadata';
    private String[] ns_map_type_info = new List<String>{
      SOAP_M_URI,
      'MetadataService'
    };

    public MetadataService.SaveResult[] createMetadata(
      MetadataService.Metadata[] metadata
    ) {
      MetadataService.createMetadata_element request_x = new MetadataService.createMetadata_element();
      request_x.metadata = metadata;

      MetadataService.createMetadataResponse_element response_x;
      Map<String, MetadataService.createMetadataResponse_element> response_map_x = new Map<String, MetadataService.createMetadataResponse_element>();
      response_map_x.put('response_x', response_x);

      WebServiceCallout.invoke(
        this,
        request_x,
        response_map_x,
        new List<String>{
          endpoint_x,
          '',
          SOAP_M_URI,
          'createMetadata',
          SOAP_M_URI,
          'createMetadataResponse',
          'MetadataService.createMetadataResponse_element'
        }
      );

      response_x = response_map_x.get('response_x');
      return response_x == null ? null : response_x.result;
    }
  }

  public class SessionHeader_element {
    public String sessionId;
    private String[] sessionId_type_info = new List<String>{
      'sessionId',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{ 'sessionId' };
  }

  public class CallOptions_element {
    public String client;
    public String defaultNamespace;
    private String[] client_type_info = new List<String>{
      'client',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] defaultNamespace_type_info = new List<String>{
      'defaultNamespace',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{
      'client',
      'defaultNamespace'
    };
  }

  public class AllOrNoneHeader_element {
    public Boolean allOrNone;
    private String[] allOrNone_type_info = new List<String>{
      'allOrNone',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{ 'allOrNone' };
  }

  public class createMetadata_element {
    public MetadataService.Metadata[] metadata;
    private String[] metadata_type_info = new List<String>{
      'metadata',
      SOAP_M_URI,
      null,
      '0',
      '-1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{ 'metadata' };
  }

  public class createMetadataResponse_element {
    public MetadataService.SaveResult[] result;
    private String[] result_type_info = new List<String>{
      'result',
      SOAP_M_URI,
      null,
      '0',
      '-1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{ 'result' };
  }

  public class SaveResult {
    public MetadataService.Error[] errors;
    public String fullName;
    public Boolean success;
    private String[] errors_type_info = new List<String>{
      'errors',
      SOAP_M_URI,
      null,
      '0',
      '-1',
      'false'
    };
    private String[] fullName_type_info = new List<String>{
      'fullName',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] success_type_info = new List<String>{
      'success',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{
      'errors',
      'fullName',
      'success'
    };
  }

  public class Error {
    public String[] fields;
    public String message;
    public String statusCode;
    private String[] fields_type_info = new List<String>{
      'fields',
      SOAP_M_URI,
      null,
      '0',
      '-1',
      'false'
    };
    private String[] message_type_info = new List<String>{
      'message',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] statusCode_type_info = new List<String>{
      'statusCode',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{
      'fields',
      'message',
      'statusCode'
    };
  }

  public class CustomObject extends Metadata {
    public String type = 'CustomObject';
    public String fullName;
    private String[] fullName_type_info = new List<String>{
      'fullName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    public String deploymentStatus;
    public String description;
    public Boolean enableActivities;
    public Boolean enableBulkApi;
    public Boolean enableFeeds;
    public Boolean enableHistory;
    public Boolean enableReports;
    public Boolean enableSearch;
    public Boolean enableSharing;
    public Boolean enableStreamingApi;
    public String label;
    public MetadataService.CustomField nameField;
    public String pluralLabel;
    public String sharingModel;
    private String[] deploymentStatus_type_info = new List<String>{
      'deploymentStatus',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] description_type_info = new List<String>{
      'description',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableActivities_type_info = new List<String>{
      'enableActivities',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableBulkApi_type_info = new List<String>{
      'enableBulkApi',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableFeeds_type_info = new List<String>{
      'enableFeeds',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableHistory_type_info = new List<String>{
      'enableHistory',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableReports_type_info = new List<String>{
      'enableReports',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableSearch_type_info = new List<String>{
      'enableSearch',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableSharing_type_info = new List<String>{
      'enableSharing',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] enableStreamingApi_type_info = new List<String>{
      'enableStreamingApi',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] label_type_info = new List<String>{
      'label',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] nameField_type_info = new List<String>{
      'nameField',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] pluralLabel_type_info = new List<String>{
      'pluralLabel',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] sharingModel_type_info = new List<String>{
      'sharingModel',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] type_att_info = new List<String>{ 'xsi:type' };
    private String[] field_order_type_info = new List<String>{
      'fullName',
      'deploymentStatus',
      'description',
      'enableActivities',
      'enableBulkApi',
      'enableFeeds',
      'enableHistory',
      'enableReports',
      'enableSearch',
      'enableSharing',
      'enableStreamingApi',
      'label',
      'nameField',
      'pluralLabel',
      'sharingModel'
    };
  }

  public class CustomField extends Metadata {
    public String type = 'CustomField';
    public String fullName;
    private String[] fullName_type_info = new List<String>{
      'fullName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    public String defaultValue;
    public String deleteConstraint;
    public String description;
    public String displayFormat;
    public Boolean externalId;
    public String formula;
    public String inlineHelpText;
    public String label;
    public Integer length;
    public Integer precision;
    public String referenceTo;
    public String relationshipLabel;
    public String relationshipName;
    public Integer relationshipOrder;
    public Boolean reparentableMasterDetail;
    public Boolean required;
    public Integer scale;
    public Integer startingNumber;
    public String type_x;
    public Boolean unique;
    public MetadataService.ValueSet valueSet;
    public Integer visibleLines;
    private String[] defaultValue_type_info = new List<String>{
      'defaultValue',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] deleteConstraint_type_info = new List<String>{
      'deleteConstraint',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] description_type_info = new List<String>{
      'description',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] displayFormat_type_info = new List<String>{
      'displayFormat',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] externalId_type_info = new List<String>{
      'externalId',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] formula_type_info = new List<String>{
      'formula',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] inlineHelpText_type_info = new List<String>{
      'inlineHelpText',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] label_type_info = new List<String>{
      'label',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] length_type_info = new List<String>{
      'length',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] precision_type_info = new List<String>{
      'precision',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] referenceTo_type_info = new List<String>{
      'referenceTo',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] relationshipLabel_type_info = new List<String>{
      'relationshipLabel',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] relationshipName_type_info = new List<String>{
      'relationshipName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] relationshipOrder_type_info = new List<String>{
      'relationshipOrder',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] reparentableMasterDetail_type_info = new List<String>{
      'reparentableMasterDetail',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] required_type_info = new List<String>{
      'required',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] scale_type_info = new List<String>{
      'scale',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] startingNumber_type_info = new List<String>{
      'startingNumber',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] type_x_type_info = new List<String>{
      'type',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] unique_type_info = new List<String>{
      'unique',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] valueSet_type_info = new List<String>{
      'valueSet',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] visibleLines_type_info = new List<String>{
      'visibleLines',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] type_att_info = new List<String>{ 'xsi:type' };
    private String[] field_order_type_info = new List<String>{
      'fullName',
      'defaultValue',
      'deleteConstraint',
      'description',
      'displayFormat',
      'externalId',
      'formula',
      'inlineHelpText',
      'label',
      'length',
      'precision',
      'referenceTo',
      'relationshipLabel',
      'relationshipName',
      'relationshipOrder',
      'reparentableMasterDetail',
      'required',
      'scale',
      'startingNumber',
      'type_x',
      'unique',
      'valueSet',
      'visibleLines'
    };
  }

  public class ValidationRule extends Metadata {
    public String type = 'ValidationRule';
    public String fullName;
    private String[] fullName_type_info = new List<String>{
      'fullName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    public Boolean active;
    public String description;
    public String errorConditionFormula;
    public String errorDisplayField;
    public String errorMessage;
    private String[] active_type_info = new List<String>{
      'active',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] description_type_info = new List<String>{
      'description',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] errorConditionFormula_type_info = new List<String>{
      'errorConditionFormula',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] errorDisplayField_type_info = new List<String>{
      'errorDisplayField',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] errorMessage_type_info = new List<String>{
      'errorMessage',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] type_att_info = new List<String>{ 'xsi:type' };
    private String[] field_order_type_info = new List<String>{
      'fullName',
      'active',
      'description',
      'errorConditionFormula',
      'errorDisplayField',
      'errorMessage'
    };
  }

  public class PermissionSet extends Metadata {
    public String type = 'PermissionSet';
    public String fullName;
    private String[] fullName_type_info = new List<String>{
      'fullName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    public String description;
    public MetadataService.FieldPermissions[] fieldPermissions;
    public Boolean hasActivationRequired;
    public String label;
    private String[] description_type_info = new List<String>{
      'description',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] fieldPermissions_type_info = new List<String>{
      'fieldPermissions',
      SOAP_M_URI,
      null,
      '0',
      '-1',
      'false'
    };
    private String[] hasActivationRequired_type_info = new List<String>{
      'hasActivationRequired',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] label_type_info = new List<String>{
      'label',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] type_att_info = new List<String>{ 'xsi:type' };
    private String[] field_order_type_info = new List<String>{
      'fullName',
      'description',
      'fieldPermissions',
      'hasActivationRequired',
      'label'
    };
  }

  public class FieldPermissions {
    public Boolean editable;
    public String field;
    public Boolean readable;
    private String[] editable_type_info = new List<String>{
      'editable',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] field_type_info = new List<String>{
      'field',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] readable_type_info = new List<String>{
      'readable',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{
      'editable',
      'field',
      'readable'
    };
  }

  public class ValueSet {
    public Boolean restricted;
    public MetadataService.ValueSetValuesDefinition valueSetDefinition;
    public String valueSetName;
    private String[] restricted_type_info = new List<String>{
      'restricted',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] valueSetDefinition_type_info = new List<String>{
      'valueSetDefinition',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] valueSetName_type_info = new List<String>{
      'valueSetName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{
      'restricted',
      'valueSetDefinition',
      'valueSetName'
    };
  }

  public class ValueSetValuesDefinition {
    public Boolean sorted;
    public MetadataService.CustomValue[] value;
    private String[] sorted_type_info = new List<String>{
      'sorted',
      SOAP_M_URI,
      null,
      '1',
      '1',
      'false'
    };
    private String[] value_type_info = new List<String>{
      'value',
      SOAP_M_URI,
      null,
      '0',
      '-1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] field_order_type_info = new List<String>{
      'sorted',
      'value'
    };
  }

  public class CustomValue extends Metadata {
    public String type = 'CustomValue';
    public String fullName;
    private String[] fullName_type_info = new List<String>{
      'fullName',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    public Boolean default_x;
    public String label;
    private String[] default_x_type_info = new List<String>{
      'default',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] label_type_info = new List<String>{
      'label',
      SOAP_M_URI,
      null,
      '0',
      '1',
      'false'
    };
    private String[] apex_schema_type_info = new List<String>{
      SOAP_M_URI,
      'true',
      'false'
    };
    private String[] type_att_info = new List<String>{ 'xsi:type' };
    private String[] field_order_type_info = new List<String>{
      'fullName',
      'default_x',
      'label'
    };
  }
}
