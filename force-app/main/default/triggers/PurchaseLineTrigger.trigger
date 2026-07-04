trigger PurchaseLineTrigger on PurchaseLine__c(after insert, after delete, after update) {
	// Recalculates TotalItems and GrandTotal on Purchase__c from lines
	Set<Id> purchaseIds = new Set<Id>();

	if (Trigger.isInsert || Trigger.isUpdate) {
		for (PurchaseLine__c line : Trigger.new) {
			if (line.PurchaseId__c != null) {
				purchaseIds.add(line.PurchaseId__c);
			}
		}
	}

	if (Trigger.isDelete) {
		for (PurchaseLine__c line : Trigger.old) {
			if (line.PurchaseId__c != null) {
				purchaseIds.add(line.PurchaseId__c);
			}
		}
	}

	if (!purchaseIds.isEmpty()) {
		recalculatePurchases(purchaseIds);
	}
}

static void recalculatePurchases(Set<Id> purchaseIds) {
	// Aggregates line totals and updates Purchase records
	List<AggregateResult> results = getAggregatedResults(purchaseIds);
	Map<Id, Purchase__c> purchasesToUpdate = buildPurchasesMap(results);
	updatePurchases(purchasesToUpdate);
}

private static List<AggregateResult> getAggregatedResults(Set<Id> purchaseIds) {
	// Aggregates total items and grand total per purchase
	return [
		SELECT PurchaseId__c,
		SUM(Amount__c) totalItems,
		SUM(Amount__c * UnitCost__c) grandTotal
		FROM PurchaseLine__c
		WHERE PurchaseId__c IN :purchaseIds
		GROUP BY PurchaseId__c
	];
}

private static Map<Id, Purchase__c> buildPurchasesMap(List<AggregateResult> results) {
	// Builds Purchase objects with calculated totals
	Map<Id, Purchase__c> purchasesMap = new Map<Id, Purchase__c>();

	for (AggregateResult result : results) {
		Id purchaseId = (Id) result.get('PurchaseId__c');
		Decimal totalItems = (Decimal) result.get('totalItems');
		Decimal grandTotal = (Decimal) result.get('grandTotal');

		Purchase__c p = new Purchase__c(
			Id = purchaseId,
			TotalItems__c = totalItems != null ? totalItems : 0,
			GrandTotal__c = grandTotal != null ? grandTotal : 0
		);
		purchasesMap.put(purchaseId, p);
	}

	return purchasesMap;
}

private static void updatePurchases(Map<Id, Purchase__c> purchasesMap) {
	// Saves updated Purchase records
	if (!purchasesMap.isEmpty()) {
		update purchasesMap.values();
	}
}

