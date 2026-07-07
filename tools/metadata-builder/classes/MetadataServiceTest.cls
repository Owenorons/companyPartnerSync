@IsTest
private class MetadataServiceTest {
  private class CreateMetadataMock implements WebServiceMock {
    public void doInvoke(
      Object stub,
      Object request,
      Map<String, Object> response,
      String endpoint,
      String soapAction,
      String requestName,
      String responseNS,
      String responseName,
      String responseType
    ) {
      MetadataService.createMetadataResponse_element responseElement = new MetadataService.createMetadataResponse_element();

      MetadataService.SaveResult result = new MetadataService.SaveResult();
      result.fullName = 'Deal_Registration__c';
      result.success = true;

      responseElement.result = new List<MetadataService.SaveResult>{ result };
      response.put('response_x', responseElement);
    }
  }

  @IsTest
  static void createMetadataReturnsSaveResults() {
    Test.setMock(WebServiceMock.class, new CreateMetadataMock());

    MetadataService.MetadataPort port = new MetadataService.MetadataPort();
    port.SessionHeader = new MetadataService.SessionHeader_element();
    port.SessionHeader.sessionId = UserInfo.getSessionId();

    MetadataService.CustomObject customObject = new MetadataService.CustomObject();
    customObject.fullName = 'Deal_Registration__c';
    customObject.label = 'Deal Registration';
    customObject.pluralLabel = 'Deal Registrations';
    customObject.deploymentStatus = 'Deployed';
    customObject.sharingModel = 'ReadWrite';
    customObject.nameField = new MetadataService.CustomField();
    customObject.nameField.label = 'Deal Registration Number';
    customObject.nameField.type_x = 'AutoNumber';
    customObject.nameField.displayFormat = 'DR-{000000}';
    customObject.nameField.startingNumber = 1;

    Test.startTest();
    MetadataService.SaveResult[] results = port.createMetadata(
      new List<MetadataService.Metadata>{ customObject }
    );
    Test.stopTest();

    System.assertEquals(1, results.size());
    System.assertEquals(true, results[0].success);
    System.assertEquals('Deal_Registration__c', results[0].fullName);
  }
}
