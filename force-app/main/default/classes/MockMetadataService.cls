@IsTest
public class MockMetadataService implements SandboxMetadataBuilder.IMetadataService {
  public List<List<MetadataService.Metadata>> capturedBatches = new List<List<MetadataService.Metadata>>();
  public Boolean returnErrors = false;

  public MetadataService.SaveResult[] createMetadata(
    MetadataService.Metadata[] metadataItems
  ) {
    capturedBatches.add(new List<MetadataService.Metadata>(metadataItems));

    List<MetadataService.SaveResult> results = new List<MetadataService.SaveResult>();

    for (MetadataService.Metadata metadataItem : metadataItems) {
      MetadataService.SaveResult result = new MetadataService.SaveResult();
      result.success = !returnErrors;
      result.fullName = getFullName(metadataItem);

      if (returnErrors) {
        MetadataService.Error err = new MetadataService.Error();
        err.message = 'Mock metadata failure';
        err.statusCode = 'MOCK_METADATA_FAILURE';
        result.errors = new List<MetadataService.Error>{ err };
      }

      results.add(result);
    }

    return results;
  }

  private String getFullName(MetadataService.Metadata metadataItem) {
    if (metadataItem instanceof MetadataService.CustomObject) {
      return ((MetadataService.CustomObject) metadataItem).fullName;
    }
    if (metadataItem instanceof MetadataService.CustomField) {
      return ((MetadataService.CustomField) metadataItem).fullName;
    }
    if (metadataItem instanceof MetadataService.ValidationRule) {
      return ((MetadataService.ValidationRule) metadataItem).fullName;
    }
    if (metadataItem instanceof MetadataService.PermissionSet) {
      return ((MetadataService.PermissionSet) metadataItem).fullName;
    }
    return metadataItem.fullName;
  }

  public Integer getBatchCount() {
    return capturedBatches.size();
  }

  public Integer getTotalMetadataCount() {
    Integer total = 0;
    for (List<MetadataService.Metadata> batch : capturedBatches) {
      total += batch.size();
    }
    return total;
  }

  public MetadataService.Metadata getFirstMetadataFromBatch(
    Integer batchIndex
  ) {
    return capturedBatches[batchIndex][0];
  }
}
