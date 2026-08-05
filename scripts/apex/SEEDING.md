# PartnerSync seed data

Run the scripts as three separate Salesforce CLI commands and in this order:

```sh
sf apex run --file scripts/apex/seed-access-groups.apex --target-org <org>
sf apex run --file scripts/apex/seed-business-data.apex --target-org <org>
sf apex run --file scripts/apex/seed-partner-users.apex --target-org <org>
```

The transaction boundary is required because Salesforce prohibits setup-object
DML (`Group`, `User`, `GroupMember`, and permission assignments) in the same
transaction as business-record DML.

Before step 3:

1. Deploy the custom `PartnerSync Partner Tester` profile.
2. Enable the Alderbrook Logistics Account as a Salesforce partner account.
3. Ensure its Account owner has a User Role.
4. Ensure Salesforce and Partner Community licenses are available.

All scripts are rerun-safe. The access and user scripts create only missing
records. The business script performs no DML if its fixture accounts already
exist.

Step 3 creates two named personas:

- a partner tester assigned `PSG_Partner_User`;
- an internal administrator tester assigned `PSG_Internal_Administrator`.
