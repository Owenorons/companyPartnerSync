@IsTest
private class PartnerContentServiceTest {
  @IsTest
  static void partnerBrowsesCategoriesAndDownloadsVisibleContent() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Content Partner'
    );
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Partner_Content__c visible = PartnerSyncTestDataFactory.content(
      'All Partners'
    );
    visible.Content_Document_Id__c = '069000000000001AAA';
    insert visible;
    Partner_Content__c hidden = PartnerSyncTestDataFactory.content(
      'Restricted'
    );
    hidden.Partner_Tier__c = 'Silver';
    insert hidden;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_Content__c = true)
      );
      List<PartnerContentDTO> available = PartnerContentController.getAvailableContent();
      Assert.areEqual(1, available.size());
      Assert.areEqual(visible.Id, available[0].contentId);
      Assert.isTrue(PartnerContentController.getCategories().size() > 0);

      PartnerContentDownloadDTO download = PartnerContentController.getDownloadUrl(
        visible.Id
      );
      Assert.areEqual(visible.Id, download.contentId);
      Assert.isTrue(download.downloadUrl.contains('069000000000001AAA'));
      Assert.areEqual(
        1,
        [
          SELECT COUNT()
          FROM Audit_Log__c
          WHERE Record_Id__c = :String.valueOf(visible.Id)
        ]
      );
    }
  }

  @IsTest
  static void contentAdministratorListsAndUpdatesContent() {
    User administrator = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      administrator.Id,
      'PartnerSync_Content_Admin'
    );
    System.runAs(administrator) {
      Partner_Content__c content = PartnerSyncTestDataFactory.content(
        'All Partners'
      );
      insert content;

      List<PartnerContentAdminDTO> records = PartnerContentController.getAllContent();
      Assert.areEqual(1, records.size());
      PartnerContentAdminDTO updateRequest = records[0];
      updateRequest.title = 'Updated Partner Guide';
      updateRequest.description = 'Updated through the admin controller';
      updateRequest.category = 'Marketing';
      updateRequest.visibility = 'All Partners';
      updateRequest.isActive = true;
      updateRequest.featured = false;
      updateRequest.sortOrder = 5;

      PartnerContentAdminDTO updated = PartnerContentController.saveContent(
        updateRequest
      );
      Assert.areEqual('Updated Partner Guide', updated.title);
      Assert.areEqual('Marketing', updated.category);
      Assert.areEqual(
        'Updated Partner Guide',
        [SELECT Name FROM Partner_Content__c WHERE Id = :content.Id].Name
      );
    }
  }
}
