/*
 * Finds existing CRM records that may represent the applicant. These are
 * advisory matches: reviewers must acknowledge them before creating a new
 * partner Account and Contact, but no records are merged automatically.
 */
public with sharing class PartnerApplicationMatchSelector {
  public static List<PartnerApplicationMatchDTO> findPotentialMatches(
    Partner_Application__c application
  ) {
    SecurityUtil.assertReadable(Account.SObjectType);
    SecurityUtil.assertReadable(Contact.SObjectType);

    List<PartnerApplicationMatchDTO> matches = new List<PartnerApplicationMatchDTO>();
    String companyName = application.Company_Name__c;
    String website = application.Website__c;
    String submittedEmail = application.Submitted_By_Email__c;

    for (Account account : [
      SELECT Id, Name, Website
      FROM Account
      WHERE Name = :companyName OR (Website != NULL AND Website = :website)
      WITH USER_MODE
      LIMIT 10
    ]) {
      PartnerApplicationMatchDTO match = new PartnerApplicationMatchDTO();
      match.recordId = account.Id;
      match.recordType = 'Account';
      match.name = account.Name;
      match.emailOrWebsite = account.Website;
      match.matchReason = account.Name == companyName
        ? 'Company name matches'
        : 'Website matches';
      matches.add(match);
    }

    if (!String.isBlank(submittedEmail)) {
      for (Contact contact : [
        SELECT Id, Name, Email
        FROM Contact
        WHERE Email = :submittedEmail
        WITH USER_MODE
        LIMIT 10
      ]) {
        PartnerApplicationMatchDTO match = new PartnerApplicationMatchDTO();
        match.recordId = contact.Id;
        match.recordType = 'Contact';
        match.name = contact.Name;
        match.emailOrWebsite = contact.Email;
        match.matchReason = 'Contact email matches';
        matches.add(match);
      }
    }

    return matches;
  }
}
