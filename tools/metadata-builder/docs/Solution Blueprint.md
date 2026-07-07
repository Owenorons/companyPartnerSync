Solution Blueprint

Product Modules

The application should be delivered in the following modules:

Partner Onboarding

Partner Profile & Workspace

Lead Distribution & Co-Selling

Deal Registration

MDF Management

Content Hub

Performance Analytics

Notifications & Activity Tracking

Admin Configuration Console

Object Model

2.1 Standard Objects

Account

Represents the partner company.

Recommended fields

Partner_ID\_\_c (Text, External ID)

Partner_Status\_\_c (Picklist: Prospect, Pending Approval, Active, Suspended, Inactive)

Partner_Tier\_\_c (Picklist: Silver, Gold, Platinum, Strategic)

Partner_Type\_\_c (Picklist: Distributor, Reseller, Agent, Dealer, Referral)

Partner_Region\_\_c (Picklist or Text)

Partner_Capacity\_\_c (Number)

Onboarding_Status\_\_c (Picklist: Not Started, In Progress, Approved, Rejected, Complete)

Program_Start_Date\_\_c (Date)

Program_End_Date\_\_c (Date)

MDF_Annual_Budget\_\_c (Currency)

MDF_Available_Budget\_\_c (Currency)

Assigned_Channel_Manager\_\_c (Lookup User)

Primary_Partner_Admin_Contact\_\_c (Lookup Contact)

Is_Partner\_\_c (Checkbox)

Contact

Represents people working for partner organizations.

Recommended fields

Portal_Role\_\_c (Picklist: Partner Admin, Sales Rep, Marketing Rep, Finance, Executive, Read Only)

Certification_Status\_\_c (Picklist: Not Certified, Active, Expired)

Is_Partner_User\_\_c (Checkbox)

Can_Submit_Deals\_\_c (Checkbox)

Can_Submit_MDF\_\_c (Checkbox)

Can_View_Analytics\_\_c (Checkbox)

User

Experience Cloud login user.

Use standard User with partner community license mapping.

Lead

Used for distributed leads.

Recommended fields

Partner_Account\_\_c (Lookup Account)

Assigned_Partner_User\_\_c (Lookup User)

Lead_Distribution_Status\_\_c (Picklist: Pending, Assigned, Accepted, Rejected, Reassigned, Converted)

Lead_Distribution_Date\_\_c (DateTime)

Lead_Channel_Source\_\_c (Picklist)

Partner_Response_Due\_\_c (Date)

Distribution_Rule_Key\_\_c (Text)

Partner_Accepted\_\_c (Checkbox)

Opportunity

Used for partner pipeline and co-sell.

Recommended fields

Partner_Account\_\_c (Lookup Account)

Deal_Registration**c (Lookup Deal_Registration**c)

Is_Channel_Opportunity\_\_c (Checkbox)

Partner_Contribution_Type\_\_c (Picklist)

Deal_Protection_End_Date\_\_c (Date)

Partner_Application\_\_c

Captures prospective partner onboarding requests.

Key fields

Application_Number\_\_c (Auto Number)

Company_Name\_\_c (Text)

Business_Email\_\_c (Email)

Phone\_\_c (Phone)

Website\_\_c (URL)

Country\_\_c (Text/Picklist)

Region\_\_c (Text/Picklist)

Requested_Tier\_\_c (Picklist)

Partner_Type\_\_c (Picklist)

Application_Status\_\_c (Picklist: Draft, Submitted, Under Review, Approved, Rejected)

Submitted_By_Contact_Name\_\_c (Text)

Submitted_By_Email\_\_c (Email)

Assigned_Reviewer\_\_c (Lookup User)

Approval_Date\_\_c (Date)

Approval_Notes\_\_c (Long Text Area)

Source\_\_c (Picklist)

Deal_Registration\_\_c

Tracks registered deals and protection windows.

Key fields

Deal_Registration_Number\_\_c (Auto Number)

Partner_Account\_\_c (Lookup Account)

Submitted_By\_\_c (Lookup Contact)

Customer_Name\_\_c (Text)

Customer_Account\_\_c (Lookup Account, optional)

Opportunity\_\_c (Lookup Opportunity)

Status\_\_c (Picklist: Draft, Submitted, Under Review, Approved, Rejected, Expired, Closed Won, Closed Lost)

Estimated_Amount\_\_c (Currency)

Estimated_Close_Date\_\_c (Date)

Deal_Type\_\_c (Picklist)

Territory\_\_c (Text/Picklist)

Product_Family\_\_c (Text/Picklist)

Protection_Start_Date\_\_c (Date)

Protection_End_Date\_\_c (Date)

Duplicate_Check_Key\_\_c (Text, indexed if possible)

Approval_Comments\_\_c (Long Text Area)

Rejected_Reason\_\_c (Long Text Area)

MDF_Request\_\_c

Handles market development fund requests.

Key fields

MDF_Request_Number\_\_c (Auto Number)

Partner_Account\_\_c (Lookup Account)

Submitted_By\_\_c (Lookup Contact)

Status\_\_c (Picklist: Draft, Submitted, Under Review, Approved, Rejected, In Progress, Proof Submitted, Reimbursed, Closed)

Budget_Period\_\_c (Text or Lookup to budget object)

Campaign_Name\_\_c (Text)

Campaign_Type\_\_c (Picklist)

Requested_Amount\_\_c (Currency)

Approved_Amount\_\_c (Currency)

Spent_Amount\_\_c (Currency)

Expected_Leads\_\_c (Number)

Actual_Leads\_\_c (Number)

Activity_Start_Date\_\_c (Date)

Activity_End_Date\_\_c (Date)

Proof_Submitted_Date\_\_c (Date)

Reimbursement_Status\_\_c (Picklist: Not Started, Pending, Processing, Paid, Failed)

Approver\_\_c (Lookup User)

Approval_Comments\_\_c (Long Text Area)

Partner_Performance\_\_c

Stores periodic snapshots for dashboards.

Key fields

Partner_Account\_\_c (Lookup Account)

Reporting_Period_Start\_\_c (Date)

Reporting_Period_End\_\_c (Date)

Leads_Assigned\_\_c (Number)

Leads_Accepted\_\_c (Number)

Leads_Converted\_\_c (Number)

Opportunities_Created\_\_c (Number)

Opportunities_Won\_\_c (Number)

Pipeline_Value\_\_c (Currency)

Won_Value\_\_c (Currency)

MDF_Approved\_\_c (Currency)

MDF_Claimed\_\_c (Currency)

Content_Downloads\_\_c (Number)

Partner_Score\_\_c (Number)

Leaderboard_Rank\_\_c (Number)

Partner_Badge\_\_c

Stores achievements and rewards.

Key fields

Partner_Account\_\_c (Lookup Account)

Badge_Code\_\_c (Text)

Badge_Name\_\_c (Text)

Awarded_On\_\_c (Date)

Awarded_By_Process\_\_c (Text)

Reason\_\_c (Long Text Area)

Active\_\_c (Checkbox)

Partner_Activity\_\_c

Lightweight activity/audit stream.

Key fields

Partner_Account\_\_c (Lookup Account)

Related_Record_Id\_\_c (Text 18)

Related_Object\_\_c (Text)

Activity_Type\_\_c (Picklist)

Activity_Message\_\_c (Long Text Area)

Activity_DateTime\_\_c (DateTime)

Performed_By_User\_\_c (Lookup User)

Visibility\_\_c (Picklist: Internal Only, Partner Visible)

Partner_Content_Access\_\_c

Optional, if content access needs explicit mapping beyond CMS/categories.

Key fields

Partner_Account\_\_c (Lookup Account)

ContentDocumentId\_\_c (Text 18)

Content_Category\_\_c (Text)

Partner_Tier\_\_c (Text)

Region\_\_c (Text)

Access_Status\_\_c (Picklist)

Lead_Distribution_Log\_\_c

Operational trace for lead assignment.

Key fields

Lead\_\_c (Lookup Lead)

Partner_Account\_\_c (Lookup Account)

Assigned_User\_\_c (Lookup User)

Rule_Key\_\_c (Text)

Assignment_Status\_\_c (Picklist)

Assigned_On\_\_c (DateTime)

Notes\_\_c (Long Text Area)

Custom Metadata Types

These are essential.

PartnerSync_Config\_\_mdt

Global switches.

Fields

Enable_Partner_Onboarding\_\_c

Enable_Deal_Registration\_\_c

Enable_MDF\_\_c

Enable_Content_Hub\_\_c

Enable_Gamification\_\_c

Enable_Partner_Analytics\_\_c

Default_Deal_Expiry_Days\_\_c

Default_Lead_Response_Days\_\_c

Max_Open_Deals_Per_Partner\_\_c

Lead_Distribution_Rule\_\_mdt

Lead routing logic.

Fields

DeveloperName

Active\_\_c

Priority\_\_c

Region\_\_c

Country\_\_c

Industry\_\_c

Partner_Tier\_\_c

Partner_Type\_\_c

Capacity_Min\_\_c

Capacity_Max\_\_c

Assignment_Method\_\_c (Round Robin, Fixed Owner, Capacity Based)

Assign_To_User_Id\_\_c or logical key

Partner_Account_Key\_\_c

Partner_Tier_Config\_\_mdt

Partner program rules by tier.

Fields

Tier_Name\_\_c

Max_MDF_Budget\_\_c

Deal_Protection_Days\_\_c

Can_Access_Premium_Content\_\_c

Badge_Eligibility\_\_c

Analytics_Access_Level\_\_c

Approval_Routing_Config\_\_mdt

Approval routing model.

Fields

Module\_\_c

Condition_Key\_\_c

Approver_Type\_\_c

Approver_User\_\_c

Approver_Queue\_\_c

Active\_\_c

Badge_Rule_Config\_\_mdt

Gamification rules.

Fields

Badge_Code\_\_c

Badge_Name\_\_c

Metric_Name\_\_c

Operator\_\_c

Threshold\_\_c

Active\_\_c

Content_Category_Config\_\_mdt

Content grouping rules.

Fields

Category_Code\_\_c

Category_Label\_\_c

Allowed_Tiers\_\_c

Allowed_Regions\_\_c

Sort_Order\_\_c

Active\_\_c

Permission Model

Profiles should stay thin. Use Permission Sets heavily.

4.1 Base external profile

Example:

Partner_Community_Base

This profile should only provide:

login

basic page/app access

minimal standard permissions

4.2 Permission Sets

PartnerSync_Base_Access

Grants:

access to core Experience pages

read on own partner records

update own permitted records

PartnerSync_Deal_Registration_User

Grants:

create/read/edit Deal_Registration\_\_c

related lead/opportunity visibility where appropriate

PartnerSync_MDF_User

Grants:

create/read/edit MDF_Request\_\_c

upload files for proof-of-performance

PartnerSync_Content_Hub_User

Grants:

view content hub objects/components

file access through controlled mechanism

PartnerSync_Analytics_User

Grants:

read Partner_Performance\_\_c

read Partner_Badge\_\_c

PartnerSync_Partner_Admin

Grants:

manage partner users in allowed flows/processes

broader partner company visibility

company profile update access

PartnerSync_Internal_Channel_Manager

Internal permissions for managing:

partner approvals

assigned accounts

deals

MDF approvals

dashboards

PartnerSync_Internal_Admin

Full admin operations for the app.

Sharing Architecture

5.1 OWD

Set these to Private where appropriate:

Deal_Registration\_\_c

MDF_Request\_\_c

Partner_Performance\_\_c

Partner_Activity\_\_c
