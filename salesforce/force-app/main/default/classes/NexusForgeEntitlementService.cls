/**
 * NexusForge Systems — Salesforce entitlement / subscription upsert helpers.
 * Idempotent by GoldenEntitlementKey__c, then StripeSubId__c.
 * ProductSKU resolved by GoldenProductKey__c or SKUCode__c.
 * Integrates with Informatica IDMC subscription masters; no hard-coded secrets.
 */
public with sharing class NexusForgeEntitlementService {

    public class EntitlementUpsertRequest {
        @AuraEnabled public String goldenEntitlementKey;
        @AuraEnabled public String goldenAccountKey;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String goldenProductKey;
        @AuraEnabled public String skuCode;
        @AuraEnabled public Id productSkuId;
        @AuraEnabled public String tier;
        @AuraEnabled public String stripeSubId;
        @AuraEnabled public String status;
        @AuraEnabled public String correlationId;
    }

    /**
     * Upsert Entitlement__c using golden keys from Informatica MDM.
     * Returns the same UpsertResult shape as NexusForgeMDMKeyService for correlation tracing.
     */
    public static NexusForgeMDMKeyService.UpsertResult upsertEntitlement(EntitlementUpsertRequest req) {
        if (req == null) {
            throw new AuraHandledException('Entitlement upsert request is required');
        }
        if (String.isBlank(req.goldenEntitlementKey) && String.isBlank(req.stripeSubId)) {
            throw new AuraHandledException('Entitlement upsert requires GoldenEntitlementKey__c or StripeSubId__c');
        }

        Id accountId = resolveAccountId(req);
        Id productSkuId = resolveProductSkuId(req);

        Entitlement__c existing = findEntitlement(req.goldenEntitlementKey, req.stripeSubId);
        Boolean created = (existing == null);
        Entitlement__c e = created ? new Entitlement__c() : existing;

        if (accountId != null) {
            e.Account__c = accountId;
        }
        if (productSkuId != null) {
            e.ProductSKU__c = productSkuId;
        }
        if (String.isNotBlank(req.tier)) {
            e.Tier__c = req.tier;
        }
        if (String.isNotBlank(req.stripeSubId)) {
            e.StripeSubId__c = req.stripeSubId;
        }
        if (String.isNotBlank(req.status)) {
            e.Status__c = req.status;
        }
        if (String.isNotBlank(req.goldenEntitlementKey)) {
            e.GoldenEntitlementKey__c = req.goldenEntitlementKey;
        }
        if (created) {
            e.Name = String.isNotBlank(req.stripeSubId)
                ? req.stripeSubId
                : req.goldenEntitlementKey;
        }

        upsert e;

        NexusForgeMDMKeyService.UpsertResult result = new NexusForgeMDMKeyService.UpsertResult();
        result.recordId = e.Id;
        result.created = created;
        result.goldenKey = e.GoldenEntitlementKey__c;
        result.correlationId = String.isNotBlank(req.correlationId)
            ? req.correlationId
            : ('nf-ent-' + String.valueOf(Crypto.getRandomLong()).replace('-', 'n'));
        return result;
    }

    /**
     * Ensure ProductSKU__c exists for SaaS or Appliance family; idempotent by golden key / SKU code.
     */
    public static NexusForgeMDMKeyService.UpsertResult upsertProductSku(
        String goldenProductKey,
        String skuCode,
        String stripePriceId,
        String productFamily,
        String correlationId
    ) {
        if (String.isBlank(goldenProductKey) && String.isBlank(skuCode)) {
            throw new AuraHandledException('ProductSKU upsert requires GoldenProductKey__c or SKUCode__c');
        }

        ProductSKU__c existing = findProductSku(goldenProductKey, skuCode);
        Boolean created = (existing == null);
        ProductSKU__c p = created ? new ProductSKU__c() : existing;

        if (String.isNotBlank(skuCode)) {
            p.SKUCode__c = skuCode;
        }
        if (String.isNotBlank(stripePriceId)) {
            p.StripePriceId__c = stripePriceId;
        }
        if (String.isNotBlank(productFamily)) {
            p.ProductFamily__c = productFamily;
        }
        if (String.isNotBlank(goldenProductKey)) {
            p.GoldenProductKey__c = goldenProductKey;
        }
        if (created) {
            p.Name = String.isNotBlank(skuCode) ? skuCode : goldenProductKey;
        }

        upsert p;

        NexusForgeMDMKeyService.UpsertResult result = new NexusForgeMDMKeyService.UpsertResult();
        result.recordId = p.Id;
        result.created = created;
        result.goldenKey = p.GoldenProductKey__c;
        result.correlationId = String.isNotBlank(correlationId)
            ? correlationId
            : ('nf-sku-' + String.valueOf(Crypto.getRandomLong()).replace('-', 'n'));
        return result;
    }

    /**
     * Active entitlement check for Case → Device flow / Agentforce triage.
     */
    public static Boolean accountHasActiveEntitlement(Id accountId) {
        if (accountId == null) {
            return false;
        }
        Integer countActive = [
            SELECT COUNT()
            FROM Entitlement__c
            WHERE Account__c = :accountId AND Status__c IN ('Active', 'Trialing')
        ];
        return countActive > 0;
    }

    private static Id resolveAccountId(EntitlementUpsertRequest req) {
        if (req.accountId != null) {
            return req.accountId;
        }
        if (String.isNotBlank(req.goldenAccountKey)) {
            List<Account> accts = [
                SELECT Id FROM Account WHERE GoldenAccountKey__c = :req.goldenAccountKey LIMIT 1
            ];
            if (!accts.isEmpty()) {
                return accts[0].Id;
            }
        }
        return null;
    }

    private static Id resolveProductSkuId(EntitlementUpsertRequest req) {
        if (req.productSkuId != null) {
            return req.productSkuId;
        }
        ProductSKU__c p = findProductSku(req.goldenProductKey, req.skuCode);
        return p == null ? null : p.Id;
    }

    private static Entitlement__c findEntitlement(String goldenKey, String stripeSubId) {
        if (String.isNotBlank(goldenKey)) {
            List<Entitlement__c> byKey = [
                SELECT Id, Name, GoldenEntitlementKey__c, Account__c, ProductSKU__c, Tier__c, StripeSubId__c, Status__c
                FROM Entitlement__c
                WHERE GoldenEntitlementKey__c = :goldenKey
                LIMIT 1
            ];
            if (!byKey.isEmpty()) {
                return byKey[0];
            }
        }
        if (String.isNotBlank(stripeSubId)) {
            List<Entitlement__c> byStripe = [
                SELECT Id, Name, GoldenEntitlementKey__c, Account__c, ProductSKU__c, Tier__c, StripeSubId__c, Status__c
                FROM Entitlement__c
                WHERE StripeSubId__c = :stripeSubId
                LIMIT 1
            ];
            if (!byStripe.isEmpty()) {
                return byStripe[0];
            }
        }
        return null;
    }

    private static ProductSKU__c findProductSku(String goldenKey, String skuCode) {
        if (String.isNotBlank(goldenKey)) {
            List<ProductSKU__c> byKey = [
                SELECT Id, Name, GoldenProductKey__c, SKUCode__c, StripePriceId__c, ProductFamily__c
                FROM ProductSKU__c
                WHERE GoldenProductKey__c = :goldenKey
                LIMIT 1
            ];
            if (!byKey.isEmpty()) {
                return byKey[0];
            }
        }
        if (String.isNotBlank(skuCode)) {
            List<ProductSKU__c> byCode = [
                SELECT Id, Name, GoldenProductKey__c, SKUCode__c, StripePriceId__c, ProductFamily__c
                FROM ProductSKU__c
                WHERE SKUCode__c = :skuCode
                LIMIT 1
            ];
            if (!byCode.isEmpty()) {
                return byCode[0];
            }
        }
        return null;
    }
}
