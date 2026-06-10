

public class PartnerSyncHandledException extends Exception {}


public with sharing class TenantConfigService {
    private static Tenant_Config__mdt cachedConfig;

    private static Tenant_Config__mdt getConfig() {
        if (cachedConfig == null) {
            cachedConfig = Tenant_Config__mdt.getInstance('Default');
        }

        if (cachedConfig == null) {
            throw new PartnerSyncHandledException(
                'Tenant configuration is missing. Please contact your administrator.'
            );
        }

        return cachedConfig;
    }

    public static Boolean isOnboardingEnabled() {
        return getConfig().Enable_Onboarding__c;
    }

    public static Boolean isDealsEnabled() {
        return getConfig().Enable_Deals__c;
    }

    public static Boolean isLeadsEnabled() {
        return getConfig().Enable_Leads__c;
    }

    public static Boolean isMdfEnabled() {
        return getConfig().Enable_MDF__c;
    }

    public static Boolean isAiEnabled() {
        return getConfig().Enable_AI__c;
    }

    public static Integer getDealExpiryDays() {
        Decimal value = getConfig().Default_Deal_Expiry_Days__c;
        return value == null ? 30 : Integer.valueOf(value);
    }

    public static Integer getLeadSlaHours() {
        Decimal value = getConfig().Lead_SLA_Hours__c;
        return value == null ? 48 : Integer.valueOf(value);
    }

    public static String getEdition() {
        return getConfig().Edition__c;
    }
}


public with sharing class SecurityUtil {

    public static void assertReadable(Schema.SObjectType objectType) {
        if (!objectType.getDescribe().isAccessible()) {
            throw new PartnerSyncHandledException('You do not have permission to read this data.');
        }
    }

    public static void assertCreateable(Schema.SObjectType objectType) {
        if (!objectType.getDescribe().isCreateable()) {
            throw new PartnerSyncHandledException('You do not have permission to create this record.');
        }
    }

    public static void assertUpdateable(Schema.SObjectType objectType) {
        if (!objectType.getDescribe().isUpdateable()) {
            throw new PartnerSyncHandledException('You do not have permission to update this record.');
        }
    }

    public static List<SObject> stripForCreate(List<SObject> records) {
        return Security.stripInaccessible(
            AccessType.CREATABLE,
            records
        ).getRecords();
    }

    public static List<SObject> stripForUpdate(List<SObject> records) {
        return Security.stripInaccessible(
            AccessType.UPDATABLE,
            records
        ).getRecords();
    }

    public static List<SObject> stripForRead(List<SObject> records) {
        return Security.stripInaccessible(
            AccessType.READABLE,
            records
        ).getRecords();
    }
}


public with sharing class PartnerAccessService {

    public static Id getCurrentPartnerAccountId() {
        User currentUser = [
            SELECT Id, ContactId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (currentUser.ContactId == null || currentUser.Contact.AccountId == null) {
            throw new PartnerSyncHandledException(
                'The current user is not linked to a partner account.'
            );
        }

        return currentUser.Contact.AccountId;
    }

    public static Contact getCurrentPartnerContact() {
        User currentUser = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (currentUser.ContactId == null) {
            throw new PartnerSyncHandledException(
                'The current user is not linked to a partner contact.'
            );
        }

        return [
            SELECT Id, AccountId, Name, Email
            FROM Contact
            WHERE Id = :currentUser.ContactId
            LIMIT 1
        ];
    }

    public static Boolean isInternalUser() {
        User currentUser = [
            SELECT UserType
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        return currentUser.UserType == 'Standard';
    }

    public static void assertCurrentUserCanAccessPartnerAccount(Id partnerAccountId) {
        if (isInternalUser()) {
            return;
        }

        Id currentPartnerAccountId = getCurrentPartnerAccountId();

        if (partnerAccountId != currentPartnerAccountId) {
            throw new PartnerSyncHandledException('Record not accessible.');
        }
    }
}

public with sharing class DealRegistrationRequestDTO {
    @AuraEnabled public String customerName;
    @AuraEnabled public String customerEmail;
    @AuraEnabled public Decimal dealValue;
    @AuraEnabled public String stage;
    @AuraEnabled public Date expectedCloseDate;
    @AuraEnabled public String description;
}

public with sharing class DealRegistrationResultDTO {
    @AuraEnabled public Id dealId;
    @AuraEnabled public String dealNumber;
    @AuraEnabled public String status;
}

public with sharing class DealRegistrationListDTO {
    @AuraEnabled public Id dealId;
    @AuraEnabled public String dealNumber;
    @AuraEnabled public String customerName;
    @AuraEnabled public String customerEmail;
    @AuraEnabled public Decimal dealValue;
    @AuraEnabled public String stage;
    @AuraEnabled public String status;
    @AuraEnabled public Date expectedCloseDate;
    @AuraEnabled public Date protectionEndDate;
}

public with sharing class DealRegistrationSelector {

    public static List<Deal_Registration__c> findActiveDuplicates(
        String customerName,
        String customerEmail
    ) {
        SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

        return [
            SELECT Id, Name, Customer_Name__c, Customer_Email__c, Status__c
            FROM Deal_Registration__c
            WHERE Status__c IN ('Submitted', 'Under Review', 'Approved')
            AND (
                Customer_Name__c = :customerName
                OR Customer_Email__c = :customerEmail
            )
            LIMIT 10
        ];
    }

    public static List<Deal_Registration__c> selectByPartnerAccount(Id partnerAccountId) {
        SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

        return [
            SELECT Id,
                   Name,
                   Customer_Name__c,
                   Customer_Email__c,
                   Deal_Value__c,
                   Stage__c,
                   Status__c,
                   Expected_Close_Date__c,
                   Protection_End_Date__c
            FROM Deal_Registration__c
            WHERE Partner_Account__c = :partnerAccountId
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    public static Deal_Registration__c selectPartnerDealById(Id dealId, Id partnerAccountId) {
        SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

        List<Deal_Registration__c> rows = [
            SELECT Id,
                   Name,
                   Partner_Account__c,
                   Customer_Name__c,
                   Customer_Email__c,
                   Deal_Value__c,
                   Stage__c,
                   Status__c,
                   Expected_Close_Date__c,
                   Protection_End_Date__c
            FROM Deal_Registration__c
            WHERE Id = :dealId
            AND Partner_Account__c = :partnerAccountId
            LIMIT 1
        ];

        if (rows.isEmpty()) {
            throw new PartnerSyncHandledException('Deal not found or not accessible.');
        }

        return rows[0];
    }
}

public with sharing class DealRegistrationDomain {

    public static void validateSubmit(DealRegistrationRequestDTO req) {
        if (req == null) {
            throw new PartnerSyncHandledException('Deal request is required.');
        }

        if (String.isBlank(req.customerName)) {
            throw new PartnerSyncHandledException('Customer name is required.');
        }

        if (req.dealValue != null && req.dealValue < 0) {
            throw new PartnerSyncHandledException('Deal value cannot be negative.');
        }

        if (req.expectedCloseDate != null && req.expectedCloseDate < Date.today()) {
            throw new PartnerSyncHandledException('Expected close date cannot be in the past.');
        }
    }

    public static Deal_Registration__c buildSubmittedDeal(
        DealRegistrationRequestDTO req,
        Id partnerAccountId,
        Id submittedByContactId
    ) {
        validateSubmit(req);

        Deal_Registration__c deal = new Deal_Registration__c();
        deal.Partner_Account__c = partnerAccountId;
        deal.Submitted_By__c = submittedByContactId;
        deal.Customer_Name__c = req.customerName == null ? null : req.customerName.trim();
        deal.Customer_Email__c = req.customerEmail == null ? null : req.customerEmail.trim();
        deal.Deal_Value__c = req.dealValue;
        deal.Stage__c = String.isBlank(req.stage) ? 'Prospecting' : req.stage;
        deal.Expected_Close_Date__c = req.expectedCloseDate;
        deal.Description__c = req.description;
        deal.Status__c = 'Submitted';
        deal.Submitted_Date__c = System.now();
        deal.Conflict_Status__c = 'Not Checked';

        return deal;
    }

    public static DealRegistrationResultDTO toResultDTO(Deal_Registration__c deal) {
        DealRegistrationResultDTO dto = new DealRegistrationResultDTO();
        dto.dealId = deal.Id;
        dto.dealNumber = deal.Name;
        dto.status = deal.Status__c;
        return dto;
    }

    public static DealRegistrationListDTO toListDTO(Deal_Registration__c deal) {
        DealRegistrationListDTO dto = new DealRegistrationListDTO();
        dto.dealId = deal.Id;
        dto.dealNumber = deal.Name;
        dto.customerName = deal.Customer_Name__c;
        dto.customerEmail = deal.Customer_Email__c;
        dto.dealValue = deal.Deal_Value__c;
        dto.stage = deal.Stage__c;
        dto.status = deal.Status__c;
        dto.expectedCloseDate = deal.Expected_Close_Date__c;
        dto.protectionEndDate = deal.Protection_End_Date__c;
        return dto;
    }
}

public with sharing class DealRegistrationService {

    public static DealRegistrationResultDTO submitDeal(DealRegistrationRequestDTO req) {
        if (!TenantConfigService.isDealsEnabled()) {
            throw new PartnerSyncHandledException('Deal registration is not enabled.');
        }

        SecurityUtil.assertCreateable(Deal_Registration__c.SObjectType);

        Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
        Contact partnerContact = PartnerAccessService.getCurrentPartnerContact();

        DealRegistrationDomain.validateSubmit(req);

        List<Deal_Registration__c> duplicates =
            DealRegistrationSelector.findActiveDuplicates(
                req.customerName,
                req.customerEmail
            );

        if (!duplicates.isEmpty()) {
            throw new PartnerSyncHandledException(
                'A deal already exists for this customer and is currently active.'
            );
        }

        Deal_Registration__c deal =
            DealRegistrationDomain.buildSubmittedDeal(
                req,
                partnerAccountId,
                partnerContact.Id
            );

        List<SObject> sanitized = SecurityUtil.stripForCreate(
            new List<SObject>{ deal }
        );

        insert sanitized;

        Deal_Registration__c insertedDeal = (Deal_Registration__c) sanitized[0];

        insertedDeal = [
            SELECT Id, Name, Status__c
            FROM Deal_Registration__c
            WHERE Id = :insertedDeal.Id
            LIMIT 1
        ];

        return DealRegistrationDomain.toResultDTO(insertedDeal);
    }

    public static List<DealRegistrationListDTO> getMyDeals() {
        if (!TenantConfigService.isDealsEnabled()) {
            throw new PartnerSyncHandledException('Deal registration is not enabled.');
        }

        Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

        List<DealRegistrationListDTO> results = new List<DealRegistrationListDTO>();

        for (Deal_Registration__c deal :
            DealRegistrationSelector.selectByPartnerAccount(partnerAccountId)
        ) {
            results.add(DealRegistrationDomain.toListDTO(deal));
        }

        return results;
    }

    public static DealRegistrationListDTO getMyDeal(Id dealId) {
        if (dealId == null) {
            throw new PartnerSyncHandledException('Deal Id is required.');
        }

        Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

        Deal_Registration__c deal =
            DealRegistrationSelector.selectPartnerDealById(dealId, partnerAccountId);

        return DealRegistrationDomain.toListDTO(deal);
    }
}



public with sharing class DealRegistrationController {

    @AuraEnabled
    public static DealRegistrationResultDTO submitDeal(DealRegistrationRequestDTO req) {
        try {
            return DealRegistrationService.submitDeal(req);
        } catch (PartnerSyncHandledException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            throw new AuraHandledException('Unable to submit deal. Please contact support.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<DealRegistrationListDTO> getMyDeals() {
        try {
            return DealRegistrationService.getMyDeals();
        } catch (PartnerSyncHandledException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            throw new AuraHandledException('Unable to load deals. Please contact support.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static DealRegistrationListDTO getMyDeal(Id dealId) {
        try {
            return DealRegistrationService.getMyDeal(dealId);
        } catch (PartnerSyncHandledException ex) {
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            throw new AuraHandledException('Unable to load deal. Please contact support.');
        }
    }
}


public with sharing class DealReviewDecisionDTO {
    @AuraEnabled public Id dealId;
    @AuraEnabled public String decision;
    @AuraEnabled public String reviewComments;
}

public with sharing class DealReviewListDTO {
    @AuraEnabled public Id dealId;
    @AuraEnabled public String dealNumber;
    @AuraEnabled public String partnerName;
    @AuraEnabled public String customerName;
    @AuraEnabled public Decimal dealValue;
    @AuraEnabled public String status;
    @AuraEnabled public String conflictStatus;
    @AuraEnabled public Date expectedCloseDate;
}

public with sharing class DealConflictResultDTO {
    @AuraEnabled public Boolean hasConflict;
    @AuraEnabled public List<Id> conflictingDealIds;
    @AuraEnabled public String message;
}


public with sharing class DealReviewSelector {

    public static List<Deal_Registration__c> selectPendingDeals() {

        SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

        return [
            SELECT Id,
                   Name,
                   Partner_Account__c,
                   Partner_Account__r.Name,
                   Customer_Name__c,
                   Customer_Email__c,
                   Deal_Value__c,
                   Status__c,
                   Conflict_Status__c,
                   Expected_Close_Date__c
            FROM Deal_Registration__c
            WHERE Status__c IN ('Submitted', 'Under Review')
            ORDER BY CreatedDate ASC
            LIMIT 500
        ];
    }

    public static Deal_Registration__c selectInternalDeal(Id dealId) {

        SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

        List<Deal_Registration__c> rows = [
            SELECT Id,
                   Name,
                   Partner_Account__c,
                   Customer_Name__c,
                   Customer_Email__c,
                   Deal_Value__c,
                   Status__c,
                   Conflict_Status__c,
                   Expected_Close_Date__c,
                   Protection_End_Date__c,
                   Review_Comments__c
            FROM Deal_Registration__c
            WHERE Id = :dealId
            LIMIT 1
        ];

        if (rows.isEmpty()) {
            throw new PartnerSyncHandledException('Deal not found.');
        }

        return rows[0];
    }

    public static List<Deal_Registration__c> findConflictingDeals(
        Id currentDealId,
        String customerName,
        String customerEmail
    ) {

        SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

        return [
            SELECT Id,
                   Name,
                   Partner_Account__c,
                   Status__c
            FROM Deal_Registration__c
            WHERE Id != :currentDealId
            AND Status__c IN ('Submitted', 'Under Review', 'Approved')
            AND (
                Customer_Name__c = :customerName
                OR Customer_Email__c = :customerEmail
            )
            LIMIT 50
        ];
    }
}


public with sharing class DealReviewDomain {

    public static DealReviewListDTO toListDTO(Deal_Registration__c deal) {

        DealReviewListDTO dto = new DealReviewListDTO();

        dto.dealId = deal.Id;
        dto.dealNumber = deal.Name;
        dto.partnerName = deal.Partner_Account__r != null
            ? deal.Partner_Account__r.Name
            : null;

        dto.customerName = deal.Customer_Name__c;
        dto.dealValue = deal.Deal_Value__c;
        dto.status = deal.Status__c;
        dto.conflictStatus = deal.Conflict_Status__c;
        dto.expectedCloseDate = deal.Expected_Close_Date__c;

        return dto;
    }

    public static DealConflictResultDTO buildConflictResult(
        List<Deal_Registration__c> conflicts
    ) {

        DealConflictResultDTO dto = new DealConflictResultDTO();

        dto.hasConflict = !conflicts.isEmpty();
        dto.conflictingDealIds = new List<Id>();

        for (Deal_Registration__c d : conflicts) {
            dto.conflictingDealIds.add(d.Id);
        }

        dto.message = dto.hasConflict
            ? 'Potential conflict detected.'
            : 'No conflicts found.';

        return dto;
    }
}

public with sharing class DealConflictService {

    public static DealConflictResultDTO evaluateConflicts(Id dealId) {

        if (dealId == null) {
            throw new PartnerSyncHandledException('Deal Id is required.');
        }

        Deal_Registration__c deal =
            DealReviewSelector.selectInternalDeal(dealId);

        List<Deal_Registration__c> conflicts =
            DealReviewSelector.findConflictingDeals(
                deal.Id,
                deal.Customer_Name__c,
                deal.Customer_Email__c
            );

        DealConflictResultDTO result =
            DealReviewDomain.buildConflictResult(conflicts);

        if (result.hasConflict) {
            deal.Conflict_Status__c = 'Conflict';
        } else {
            deal.Conflict_Status__c = 'No Conflict';
        }

        SecurityUtil.assertUpdateable(Deal_Registration__c.SObjectType);

        List<SObject> sanitized =
            SecurityUtil.stripForUpdate(
                new List<SObject>{ deal }
            );

        update sanitized;

        return result;
    }
}

public with sharing class DealReviewService {

    public static List<DealReviewListDTO> getPendingDeals() {

        if (!PartnerAccessService.isInternalUser()) {
            throw new PartnerSyncHandledException(
                'Only internal users can review deals.'
            );
        }

        List<DealReviewListDTO> results =
            new List<DealReviewListDTO>();

        for (Deal_Registration__c deal :
            DealReviewSelector.selectPendingDeals()
        ) {
            results.add(
                DealReviewDomain.toListDTO(deal)
            );
        }

        return results;
    }

    public static void processDecision(DealReviewDecisionDTO req) {

        if (req == null || req.dealId == null) {
            throw new PartnerSyncHandledException(
                'Review request is invalid.'
            );
        }

        if (!PartnerAccessService.isInternalUser()) {
            throw new PartnerSyncHandledException(
                'Only internal users can review deals.'
            );
        }

        SecurityUtil.assertUpdateable(
            Deal_Registration__c.SObjectType
        );

        Deal_Registration__c deal =
            DealReviewSelector.selectInternalDeal(req.dealId);

        if (req.decision == 'Approve') {

            deal.Status__c = 'Approved';

            Integer protectionDays =
                TenantConfigService.getDealExpiryDays();

            deal.Protection_End_Date__c =
                Date.today().addDays(protectionDays);
        }
        else if (req.decision == 'Reject') {

            deal.Status__c = 'Rejected';
        }
        else {
            throw new PartnerSyncHandledException(
                'Unsupported review decision.'
            );
        }

        deal.Review_Comments__c = req.reviewComments;

        List<SObject> sanitized =
            SecurityUtil.stripForUpdate(
                new List<SObject>{ deal }
            );

        update sanitized;
    }
}


public with sharing class DealReviewController {

    @AuraEnabled(cacheable=true)
    public static List<DealReviewListDTO> getPendingDeals() {

        try {
            return DealReviewService.getPendingDeals();

        } catch (PartnerSyncHandledException ex) {

            throw new AuraHandledException(ex.getMessage());

        } catch (Exception ex) {

            System.debug(LoggingLevel.ERROR, ex.getMessage());

            throw new AuraHandledException(
                'Unable to load deal reviews.'
            );
        }
    }

    @AuraEnabled
    public static void processDecision(
        DealReviewDecisionDTO req
    ) {

        try {

            DealReviewService.processDecision(req);

        } catch (PartnerSyncHandledException ex) {

            throw new AuraHandledException(ex.getMessage());

        } catch (Exception ex) {

            System.debug(LoggingLevel.ERROR, ex.getMessage());

            throw new AuraHandledException(
                'Unable to process review decision.'
            );
        }
    }

    @AuraEnabled
    public static DealConflictResultDTO evaluateConflicts(
        Id dealId
    ) {

        try {

            return DealConflictService.evaluateConflicts(dealId);

        } catch (PartnerSyncHandledException ex) {

            throw new AuraHandledException(ex.getMessage());

        } catch (Exception ex) {

            System.debug(LoggingLevel.ERROR, ex.getMessage());

            throw new AuraHandledException(
                'Unable to evaluate conflicts.'
            );
        }
    }
}

public with sharing class LeadDistributionDTO {

    @AuraEnabled public Id leadId;
    @AuraEnabled public String leadName;
    @AuraEnabled public String company;
    @AuraEnabled public String email;
    @AuraEnabled public String phone;
    @AuraEnabled public String status;
    @AuraEnabled public Datetime assignedDate;
    @AuraEnabled public Datetime slaDeadline;
}

public with sharing class LeadDecisionRequestDTO {

    @AuraEnabled public Id leadId;
    @AuraEnabled public String decision;
    @AuraEnabled public String notes;
}

public with sharing class LeadConversionResultDTO {

    @AuraEnabled public Id leadId;
    @AuraEnabled public Id dealId;
    @AuraEnabled public Id opportunityId;
    @AuraEnabled public String status;
}

public with sharing class LeadDistributionSelector {

    public static List<Lead> selectAssignedLeadsByPartner(
        Id partnerAccountId
    ) {

        SecurityUtil.assertReadable(Lead.SObjectType);

        return [
            SELECT Id,
                   Name,
                   Company,
                   Email,
                   Phone,
                   Lead_Distribution_Status__c,
                   Assigned_Date__c,
                   SLA_Deadline__c,
                   Partner_Account__c
            FROM Lead
            WHERE Partner_Account__c = :partnerAccountId
            AND Lead_Distribution_Status__c IN (
                'Assigned',
                'Accepted',
                'Converted'
            )
            ORDER BY Assigned_Date__c DESC
            LIMIT 200
        ];
    }

    public static Lead selectPartnerLeadById(
        Id leadId,
        Id partnerAccountId
    ) {

        SecurityUtil.assertReadable(Lead.SObjectType);

        List<Lead> rows = [
            SELECT Id,
                   Name,
                   Company,
                   Email,
                   Phone,
                   Partner_Account__c,
                   Partner_Contact__c,
                   Lead_Distribution_Status__c,
                   Assigned_Date__c,
                   Accepted_Date__c,
                   Rejected_Date__c,
                   SLA_Deadline__c,
                   Converted_Deal__c
            FROM Lead
            WHERE Id = :leadId
            AND Partner_Account__c = :partnerAccountId
            LIMIT 1
        ];

        if (rows.isEmpty()) {
            throw new PartnerSyncHandledException(
                'Lead not found or not accessible.'
            );
        }

        return rows[0];
    }

    public static Lead selectInternalLead(Id leadId) {

        SecurityUtil.assertReadable(Lead.SObjectType);

        List<Lead> rows = [
            SELECT Id,
                   Name,
                   Company,
                   Email,
                   Phone,
                   Partner_Account__c,
                   Partner_Contact__c,
                   Lead_Distribution_Status__c,
                   Assigned_Date__c,
                   Accepted_Date__c,
                   Rejected_Date__c,
                   SLA_Deadline__c,
                   Converted_Deal__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        if (rows.isEmpty()) {
            throw new PartnerSyncHandledException('Lead not found.');
        }

        return rows[0];
    }
}


public with sharing class LeadDistributionDomain {

    public static LeadDistributionDTO toDTO(Lead l) {

        LeadDistributionDTO dto =
            new LeadDistributionDTO();

        dto.leadId = l.Id;
        dto.leadName = l.Name;
        dto.company = l.Company;
        dto.email = l.Email;
        dto.phone = l.Phone;
        dto.status = l.Lead_Distribution_Status__c;
        dto.assignedDate = l.Assigned_Date__c;
        dto.slaDeadline = l.SLA_Deadline__c;

        return dto;
    }

    public static void validateDecision(
        LeadDecisionRequestDTO req
    ) {

        if (req == null) {
            throw new PartnerSyncHandledException(
                'Decision request is required.'
            );
        }

        if (req.leadId == null) {
            throw new PartnerSyncHandledException(
                'Lead Id is required.'
            );
        }

        if (
            req.decision != 'Accepted' &&
            req.decision != 'Rejected'
        ) {
            throw new PartnerSyncHandledException(
                'Unsupported lead decision.'
            );
        }
    }
}



public with sharing class LeadDistributionService {

    public static void assignLeadToPartner(
        Id leadId,
        Id partnerAccountId,
        Id partnerContactId
    ) {

        if (!TenantConfigService.isLeadsEnabled()) {
            throw new PartnerSyncHandledException(
                'Lead distribution is disabled.'
            );
        }

        if (!PartnerAccessService.isInternalUser()) {
            throw new PartnerSyncHandledException(
                'Only internal users can assign leads.'
            );
        }

        SecurityUtil.assertUpdateable(Lead.SObjectType);

        Lead lead =
            LeadDistributionSelector.selectInternalLead(leadId);

        lead.Partner_Account__c = partnerAccountId;
        lead.Partner_Contact__c = partnerContactId;
        lead.Lead_Distribution_Status__c = 'Assigned';
        lead.Assigned_Date__c = System.now();

        Integer slaHours =
            TenantConfigService.getLeadSlaHours();

        lead.SLA_Deadline__c =
            System.now().addHours(slaHours);

        List<SObject> sanitized =
            SecurityUtil.stripForUpdate(
                new List<SObject>{ lead }
            );

        update sanitized;
    }

    public static List<LeadDistributionDTO> getMyLeads() {

        if (!TenantConfigService.isLeadsEnabled()) {
            throw new PartnerSyncHandledException(
                'Lead distribution is disabled.'
            );
        }

        Id partnerAccountId =
            PartnerAccessService.getCurrentPartnerAccountId();

        List<LeadDistributionDTO> results =
            new List<LeadDistributionDTO>();

        for (
            Lead l :
            LeadDistributionSelector.selectAssignedLeadsByPartner(
                partnerAccountId
            )
        ) {
            results.add(
                LeadDistributionDomain.toDTO(l)
            );
        }

        return results;
    }
}

public with sharing class LeadConversionService {

    public static LeadConversionResultDTO convertLead(
        Id leadId
    ) {

        if (!TenantConfigService.isDealsEnabled()) {
            throw new PartnerSyncHandledException(
                'Deal registration is disabled.'
            );
        }

        SecurityUtil.assertCreateable(
            Deal_Registration__c.SObjectType
        );

        SecurityUtil.assertCreateable(
            Opportunity.SObjectType
        );

        Id partnerAccountId =
            PartnerAccessService.getCurrentPartnerAccountId();

        Lead lead =
            LeadDistributionSelector.selectPartnerLeadById(
                leadId,
                partnerAccountId
            );

        if (
            lead.Lead_Distribution_Status__c != 'Accepted'
        ) {
            throw new PartnerSyncHandledException(
                'Lead must be accepted before conversion.'
            );
        }

        Deal_Registration__c deal =
            new Deal_Registration__c();

        deal.Partner_Account__c =
            lead.Partner_Account__c;

        deal.Submitted_By__c =
            lead.Partner_Contact__c;

        deal.Customer_Name__c =
            lead.Company;

        deal.Customer_Email__c =
            lead.Email;

        deal.Stage__c = 'Prospecting';
        deal.Status__c = 'Submitted';
        deal.Source_Lead__c = lead.Id;

        List<SObject> sanitizedDeals =
            SecurityUtil.stripForCreate(
                new List<SObject>{ deal }
            );

        insert sanitizedDeals;

        Deal_Registration__c insertedDeal =
            (Deal_Registration__c) sanitizedDeals[0];

        Opportunity opp = new Opportunity();

        opp.Name = lead.Company + ' Opportunity';
        opp.AccountId = lead.Partner_Account__c;
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(
            TenantConfigService.getDealExpiryDays()
        );

        opp.LeadSource = 'Partner Lead';

        List<SObject> sanitizedOpps =
            SecurityUtil.stripForCreate(
                new List<SObject>{ opp }
            );

        insert sanitizedOpps;

        Opportunity insertedOpp =
            (Opportunity) sanitizedOpps[0];

        insertedDeal.Opportunity__c =
            insertedOpp.Id;

        List<SObject> updateDeal =
            SecurityUtil.stripForUpdate(
                new List<SObject>{ insertedDeal }
            );

        update updateDeal;

        lead.Converted_Deal__c =
            insertedDeal.Id;

        lead.Lead_Distribution_Status__c =
            'Converted';

        List<SObject> updateLead =
            SecurityUtil.stripForUpdate(
                new List<SObject>{ lead }
            );

        update updateLead;

        LeadConversionResultDTO result =
            new LeadConversionResultDTO();

        result.leadId = lead.Id;
        result.dealId = insertedDeal.Id;
        result.opportunityId = insertedOpp.Id;
        result.status = 'Converted';

        return result;
    }
}


public with sharing class LeadDecisionService {

    public static LeadConversionResultDTO processDecision(
        LeadDecisionRequestDTO req
    ) {

        if (!TenantConfigService.isLeadsEnabled()) {
            throw new PartnerSyncHandledException(
                'Lead distribution is disabled.'
            );
        }

        LeadDistributionDomain.validateDecision(req);

        SecurityUtil.assertUpdateable(Lead.SObjectType);

        Id partnerAccountId =
            PartnerAccessService.getCurrentPartnerAccountId();

        Lead lead =
            LeadDistributionSelector.selectPartnerLeadById(
                req.leadId,
                partnerAccountId
            );

        if (
            lead.Lead_Distribution_Status__c != 'Assigned'
        ) {
            throw new PartnerSyncHandledException(
                'Only assigned leads can be processed.'
            );
        }

        if (req.decision == 'Accepted') {

            lead.Lead_Distribution_Status__c =
                'Accepted';

            lead.Accepted_Date__c =
                System.now();

            List<SObject> sanitized =
                SecurityUtil.stripForUpdate(
                    new List<SObject>{ lead }
                );

            update sanitized;

            return LeadConversionService.convertLead(
                lead.Id
            );
        }

        lead.Lead_Distribution_Status__c =
            'Rejected';

        lead.Rejected_Date__c =
            System.now();

        List<SObject> sanitized =
            SecurityUtil.stripForUpdate(
                new List<SObject>{ lead }
            );

        update sanitized;

        return null;
    }
}



public with sharing class LeadDistributionController {

    @AuraEnabled(cacheable=true)
    public static List<LeadDistributionDTO> getMyLeads() {

        try {

            return LeadDistributionService.getMyLeads();

        } catch (PartnerSyncHandledException ex) {

            throw new AuraHandledException(
                ex.getMessage()
            );

        } catch (Exception ex) {

            System.debug(
                LoggingLevel.ERROR,
                ex.getMessage()
            );

            throw new AuraHandledException(
                'Unable to load leads.'
            );
        }
    }

    @AuraEnabled
    public static LeadConversionResultDTO processDecision(
        LeadDecisionRequestDTO req
    ) {

        try {

            return LeadDecisionService.processDecision(
                req
            );

        } catch (PartnerSyncHandledException ex) {

            throw new AuraHandledException(
                ex.getMessage()
            );

        } catch (Exception ex) {

            System.debug(
                LoggingLevel.ERROR,
                ex.getMessage()
            );

            throw new AuraHandledException(
                'Unable to process lead decision.'
            );
        }
    }
}

