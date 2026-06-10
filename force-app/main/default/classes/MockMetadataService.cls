@IsTest
public class MockMetadataService implements SandboxMetadataBuilder.IMetadataService {
  public List<List<MetadataService.Metadata>> capturedBatches = new List<List<MetadataService.Metadata>>();
  public List<List<MetadataService.SaveResult>> capturedResults = new List<List<MetadataService.SaveResult>>();
  public Set<String> failingFullNames = new Set<String>();
  public Boolean returnErrors = false;

  public MetadataService.SaveResult[] createMetadata(
    MetadataService.Metadata[] metadataItems
  ) {
    capturedBatches.add(new List<MetadataService.Metadata>(metadataItems));

    List<MetadataService.SaveResult> results = new List<MetadataService.SaveResult>();

    for (MetadataService.Metadata metadataItem : metadataItems) {
      MetadataService.SaveResult result = new MetadataService.SaveResult();
      result.fullName = getFullName(metadataItem);
      Boolean shouldFail =
        returnErrors || failingFullNames.contains(result.fullName);
      result.success = !shouldFail;

      if (shouldFail) {
        MetadataService.Error err = new MetadataService.Error();
        err.message = 'Mock metadata failure';
        err.statusCode = 'MOCK_METADATA_FAILURE';
        result.errors = new List<MetadataService.Error>{ err };
      }

      results.add(result);
    }

    capturedResults.add(new List<MetadataService.SaveResult>(results));
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

  public MetadataService.Metadata getMetadata(
    Integer batchIndex,
    Integer itemIndex
  ) {
    return capturedBatches[batchIndex][itemIndex];
  }

  public MetadataService.CustomObject getCustomObject(
    Integer batchIndex,
    Integer itemIndex
  ) {
    return (MetadataService.CustomObject) getMetadata(batchIndex, itemIndex);
  }

  public MetadataService.CustomField getCustomField(
    Integer batchIndex,
    Integer itemIndex
  ) {
    return (MetadataService.CustomField) getMetadata(batchIndex, itemIndex);
  }

  public MetadataService.ValidationRule getValidationRule(
    Integer batchIndex,
    Integer itemIndex
  ) {
    return (MetadataService.ValidationRule) getMetadata(batchIndex, itemIndex);
  }

  public MetadataService.PermissionSet getPermissionSet(
    Integer batchIndex,
    Integer itemIndex
  ) {
    return (MetadataService.PermissionSet) getMetadata(batchIndex, itemIndex);
  }

  public MetadataService.SaveResult getSaveResult(
    Integer batchIndex,
    Integer itemIndex
  ) {
    return capturedResults[batchIndex][itemIndex];
  }
}
