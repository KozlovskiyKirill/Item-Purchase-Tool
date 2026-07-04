public with sharing class CartController {

	public class CartItem {
		@AuraEnabled public String itemId;
		@AuraEnabled public Integer amount;
		@AuraEnabled public Decimal unitCost;
	}

	@AuraEnabled
	public static String checkout(List<CartItem> cartItems, Id accountId) {
		// Main checkout: validates inputs, creates Purchase and PurchaseLines
		validateInputs(cartItems, accountId);
		Map<Id, CartItem> cartMap = buildCartMap(cartItems);
		Map<Id, Item__c> itemMap = fetchItems(cartMap.keySet());
		validateStock(cartMap, itemMap);
		Id purchaseId = createPurchase(accountId);
		processPurchaseLines(purchaseId, cartMap, itemMap);
		return purchaseId;
	}

	private static void validateInputs(List<CartItem> cartItems, Id accountId) {
		if (cartItems == null || cartItems.isEmpty()) {
			throw new AuraHandledException('Cart is empty');
		}
		if (accountId == null) {
			throw new AuraHandledException('Account is required');
		}
	}

	private static Map<Id, CartItem> buildCartMap(List<CartItem> cartItems) {
		// Converts cart items list to Map<Id, CartItem>
		Map<Id, CartItem> cartMap = new Map<Id, CartItem>();
		for (CartItem item : cartItems) {
			cartMap.put(item.itemId, item);
		}
		return cartMap;
	}

	private static Map<Id, Item__c> fetchItems(Set<Id> itemIds) {
		// Fetches items from DB for stock validation and unit cost
		List<Item__c> items = [SELECT Id, Name, AvailableQuantity__c, Price__c
		FROM Item__c
		WHERE Id IN :itemIds];
		return new Map<Id, Item__c>(items);
	}

	private static void validateStock(Map<Id, CartItem> cartMap, Map<Id, Item__c> itemMap) {
		// Validates that each item has enough stock for the requested amount
		for (Id itemId : cartMap.keySet()) {
			CartItem cartItem = cartMap.get(itemId);
			Item__c dbItem = itemMap.get(itemId);

			if (dbItem == null) {
				throw new AuraHandledException('Item not found: ' + itemId);
			}

			if (dbItem.AvailableQuantity__c < cartItem.amount) {
				throw new AuraHandledException(
						'Not enough stock for ' + dbItem.Name +
						'. Available: ' + dbItem.AvailableQuantity__c +
						', Requested: ' + cartItem.amount
				);
			}
		}
	}

	private static Id createPurchase(Id accountId) {
		// Creates Purchase record with account reference
		Purchase__c purchase = new Purchase__c(
				ClientId__c = accountId,
				TotalItems__c = 0,
				GrandTotal__c = 0
		);
		insert purchase;
		return purchase.Id;
	}

	private static void processPurchaseLines(Id purchaseId, Map<Id, CartItem> cartMap, Map<Id, Item__c> itemMap) {
		// Creates PurchaseLine records and reduces item stock
		List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
		List<Item__c> itemsToUpdate = new List<Item__c>();

		for (Id itemId : cartMap.keySet()) {
			CartItem cartItem = cartMap.get(itemId);
			Item__c dbItem = itemMap.get(itemId);

			PurchaseLine__c line = new PurchaseLine__c(
					PurchaseId__c = purchaseId,
					ItemId__c = itemId,
					Amount__c = cartItem.amount,
					UnitCost__c = dbItem.Price__c
			);
			lines.add(line);

			dbItem.AvailableQuantity__c -= cartItem.amount;
			itemsToUpdate.add(dbItem);
		}

		insert lines;
		update itemsToUpdate;
	}
}




}