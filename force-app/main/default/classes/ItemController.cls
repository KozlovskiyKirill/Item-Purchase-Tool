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
}