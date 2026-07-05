public with sharing class ItemController {

	@AuraEnabled(cacheable = true)
	public static List<Item__c> getItems(String familyFilter, String typeFilter, String searchTerm) {
		// Builds dynamic SOQL with optional family/type filters and search term
		String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, ' +
				'Image__c, Price__c, AvailableQuantity__c FROM Item__c';

		List<String> conditions = new List<String>();

		if (String.isNotBlank(familyFilter)) {
			conditions.add('Family__c = :familyFilter');
		}

		if (String.isNotBlank(typeFilter)) {
			conditions.add('Type__c = :typeFilter');
		}

		if (String.isNotBlank(searchTerm)) {
			String searchPattern = '%' + searchTerm + '%';
			conditions.add('(Name LIKE :searchPattern OR Description__c LIKE :searchPattern)');
		}

		if (!conditions.isEmpty()) {
			query += ' WHERE ' + String.join(conditions, ' AND ');
		}

		return Database.query(query);
	}

	@AuraEnabled(cacheable = true)
	public static List<String> getFamilyOptions() {
		// Returns available Family picklist options
		List<String> options = new List<String>();
		Schema.DescribeFieldResult fieldResult = Item__c.Family__c.getDescribe();
		for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
			options.add(entry.getLabel());
		}
		return options;
	}

	@AuraEnabled(cacheable = true)
	public static List<String> getTypeOptions() {
		// Returns available Type picklist options
		List<String> options = new List<String>();
		Schema.DescribeFieldResult fieldResult = Item__c.Type__c.getDescribe();
		for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
			options.add(entry.getLabel());
		}
		return options;
	}

	@AuraEnabled
	public static Item__c createItemWithImage(
		String name,
		String description,
		String type,
		String family,
		Decimal price,
		Decimal availableQuantity
	){
		Item__c newItem = new Item__c(
				Name = name,
				Description__c = description,
				Type__c = type,
				Family__c = family,
				Price__c = price,
				AvailableQuantity__c = availableQuantity,
				Image__c = 'https://via.placeholder.com/300x200?text=No+Image' // временная картинка
		);
		insert newItem;
		String imageUrl = fetchUnsplashImage(name);
		if(String.isNotBlank(imageUrl)){
			newItem.Image__c = imageUrl;
			update newItem;
		}
		return newItem;
	}

	private static String fetchUnsplashImage(String query){
		try{
			Unsplash_Settings__mdt settings = Unsplash_Settings__mdt.getInctance('Unsplash Config');
			String apiKey = settings.ApiKey__c;
			if (String.isBlank(apiKey)) {
				throw new AuraHandledException('Unsplash API key is not configured.');
			}
			Http http = new Http();
			HttpRequest request = new HttpRequest();
			request.setEndpoint(endpoint);
			request.setMethod('GET');
			request.setHeader('Authorization', 'Client-ID ' + apiKey);
			request.setTimeout(120000);

			HttpResponse response = http.send(request);

			if (response.getStatusCode() == 200) {
				Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
				List<Object> results = (List<Object>) result.get('results');

				if (results != null && !results.isEmpty()) {
					Map<String, Object> firstResult = (Map<String, Object>) results[0];
					Map<String, Object> urls = (Map<String, Object>) firstResult.get('urls');
					return (String) urls.get('regular');
				}
		}
		catch(Exception e){
			System.debug('Unsplash error: ' + e.getMessage());
		}
	}
	return null;
}