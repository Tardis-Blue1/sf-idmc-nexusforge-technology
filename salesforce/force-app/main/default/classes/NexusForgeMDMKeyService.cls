/**
 * NexusForge Systems — Salesforce MDM golden-key upsert helpers.
 * Coordinates with Informatica IDMC MDM golden keys for Account, Contact, and Device.
 * Idempotent: upserts by golden key first, then by natural business keys.
 * No secrets or credentials are hard-coded; Named Credentials / Custom Metadata supply endpoints.
 */
public with sharing class NexusForgeMDMKeyService {

    public class UpsertResult {
        @AuraEnabled public Id recordId;
        @AuraEnabled public Boolean created;
        @AuraEnabled public String goldenKey;
        @AuraEnabled public String correlationId;
    }

    /**
     * Upsert Account by GoldenAccountKey__c (preferred) or ForgeObserveOrgId__c.
     */
    public static UpsertResult upsertAccountByGoldenKey(
        String goldenKey,
        String name,
        String forgeObserveOrgId,
        String netSuiteCustomerId,
        String survivorshipSource,
        String correlationId
    ) {
        if (String.isBlank(goldenKey) && String.isBlank(forgeObserveOrgId)) {
            throw new AuraHandledException('Account upsert requires GoldenAccountKey__c or ForgeObserveOrgId__c');
        }

        Account existing = findAccount(goldenKey, forgeObserveOrgId);
        Boolean created = (existing == null);
        Account acct = created ? new Account() : existing;

        if (String.isNotBlank(name)) {
            acct.Name = name;
        } else if (created) {
            acct.Name = 'NexusForge Account ' + (String.isNotBlank(goldenKey) ? goldenKey : forgeObserveOrgId);
        }
        if (String.isNotBlank(goldenKey)) {
            acct.GoldenAccountKey__c = goldenKey;
        }
        if (String.isNotBlank(forgeObserveOrgId)) {
            acct.ForgeObserveOrgId__c = forgeObserveOrgId;
        }
        if (String.isNotBlank(netSuiteCustomerId)) {
            acct.NetSuiteCustomerId__c = netSuiteCustomerId;
        }
        if (String.isNotBlank(survivorshipSource)) {
            acct.MDMSurvivorshipSource__c = survivorshipSource;
        }

        upsert acct;
        return toResult(acct.Id, created, acct.GoldenAccountKey__c, correlationId);
    }

    /**
     * Upsert Contact by GoldenContactKey__c (preferred) or Auth0UserId__c.
     */
    public static UpsertResult upsertContactByGoldenKey(
        String goldenKey,
        Id accountId,
        String lastName,
        String email,
        String auth0UserId,
        Boolean productUserFlag,
        String correlationId
    ) {
        if (String.isBlank(goldenKey) && String.isBlank(auth0UserId)) {
            throw new AuraHandledException('Contact upsert requires GoldenContactKey__c or Auth0UserId__c');
        }

        Contact existing = findContact(goldenKey, auth0UserId);
        Boolean created = (existing == null);
        Contact c = created ? new Contact() : existing;

        if (accountId != null) {
            c.AccountId = accountId;
        }
        if (String.isNotBlank(lastName)) {
            c.LastName = lastName;
        } else if (created) {
            c.LastName = 'Unknown';
        }
        if (String.isNotBlank(email)) {
            c.Email = email;
        }
        if (String.isNotBlank(goldenKey)) {
            c.GoldenContactKey__c = goldenKey;
        }
        if (String.isNotBlank(auth0UserId)) {
            c.Auth0UserId__c = auth0UserId;
        }
        if (productUserFlag != null) {
            c.ProductUserFlag__c = productUserFlag;
        }

        upsert c;
        return toResult(c.Id, created, c.GoldenContactKey__c, correlationId);
    }

    /**
     * Upsert Device__c by GoldenDeviceKey__c (preferred) or Serial__c.
     */
    public static UpsertResult upsertDeviceByGoldenKey(
        String goldenKey,
        String serial,
        String firmware,
        Id accountId,
        String tenantOrgId,
        String status,
        Decimal matchConfidence,
        String correlationId
    ) {
        if (String.isBlank(goldenKey) && String.isBlank(serial)) {
            throw new AuraHandledException('Device upsert requires GoldenDeviceKey__c or Serial__c');
        }

        Device__c existing = findDevice(goldenKey, serial);
        Boolean created = (existing == null);
        Device__c d = created ? new Device__c() : existing;

        if (String.isNotBlank(serial)) {
            d.Serial__c = serial;
        }
        if (String.isNotBlank(firmware)) {
            d.Firmware__c = firmware;
        }
        if (accountId != null) {
            d.Account__c = accountId;
        }
        if (String.isNotBlank(tenantOrgId)) {
            d.TenantOrgId__c = tenantOrgId;
        }
        if (String.isNotBlank(status)) {
            d.Status__c = status;
        }
        if (String.isNotBlank(goldenKey)) {
            d.GoldenDeviceKey__c = goldenKey;
        }
        if (matchConfidence != null) {
            d.MDMMatchConfidence__c = matchConfidence;
        }
        if (created && String.isBlank(d.Name)) {
            d.Name = String.isNotBlank(serial) ? serial : goldenKey;
        }

        upsert d;
        return toResult(d.Id, created, d.GoldenDeviceKey__c, correlationId);
    }

    private static Account findAccount(String goldenKey, String forgeObserveOrgId) {
        if (String.isNotBlank(goldenKey)) {
            List<Account> byKey = [
                SELECT Id, GoldenAccountKey__c, ForgeObserveOrgId__c, NetSuiteCustomerId__c, MDMSurvivorshipSource__c, Name
                FROM Account
                WHERE GoldenAccountKey__c = :goldenKey
                LIMIT 1
            ];
            if (!byKey.isEmpty()) {
                return byKey[0];
            }
        }
        if (String.isNotBlank(forgeObserveOrgId)) {
            List<Account> byOrg = [
                SELECT Id, GoldenAccountKey__c, ForgeObserveOrgId__c, NetSuiteCustomerId__c, MDMSurvivorshipSource__c, Name
                FROM Account
                WHERE ForgeObserveOrgId__c = :forgeObserveOrgId
                LIMIT 1
            ];
            if (!byOrg.isEmpty()) {
                return byOrg[0];
            }
        }
        return null;
    }

    private static Contact findContact(String goldenKey, String auth0UserId) {
        if (String.isNotBlank(goldenKey)) {
            List<Contact> byKey = [
                SELECT Id, GoldenContactKey__c, Auth0UserId__c, ProductUserFlag__c, AccountId, LastName, Email
                FROM Contact
                WHERE GoldenContactKey__c = :goldenKey
                LIMIT 1
            ];
            if (!byKey.isEmpty()) {
                return byKey[0];
            }
        }
        if (String.isNotBlank(auth0UserId)) {
            List<Contact> byAuth = [
                SELECT Id, GoldenContactKey__c, Auth0UserId__c, ProductUserFlag__c, AccountId, LastName, Email
                FROM Contact
                WHERE Auth0UserId__c = :auth0UserId
                LIMIT 1
            ];
            if (!byAuth.isEmpty()) {
                return byAuth[0];
            }
        }
        return null;
    }

    private static Device__c findDevice(String goldenKey, String serial) {
        if (String.isNotBlank(goldenKey)) {
            List<Device__c> byKey = [
                SELECT Id, Name, GoldenDeviceKey__c, Serial__c, Firmware__c, Account__c, TenantOrgId__c, Status__c, MDMMatchConfidence__c
                FROM Device__c
                WHERE GoldenDeviceKey__c = :goldenKey
                LIMIT 1
            ];
            if (!byKey.isEmpty()) {
                return byKey[0];
            }
        }
        if (String.isNotBlank(serial)) {
            List<Device__c> bySerial = [
                SELECT Id, Name, GoldenDeviceKey__c, Serial__c, Firmware__c, Account__c, TenantOrgId__c, Status__c, MDMMatchConfidence__c
                FROM Device__c
                WHERE Serial__c = :serial
                LIMIT 1
            ];
            if (!bySerial.isEmpty()) {
                return bySerial[0];
            }
        }
        return null;
    }

    private static UpsertResult toResult(Id recordId, Boolean created, String goldenKey, String correlationId) {
        UpsertResult r = new UpsertResult();
        r.recordId = recordId;
        r.created = created;
        r.goldenKey = goldenKey;
        r.correlationId = String.isNotBlank(correlationId) ? correlationId : generateCorrelationId();
        return r;
    }

    @TestVisible
    private static String generateCorrelationId() {
        return 'nf-' + String.valueOf(Crypto.getRandomLong()).replace('-', 'n');
    }
}
