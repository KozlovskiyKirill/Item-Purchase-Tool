public with sharing class ItemController{
	@AuraEnabled(cacheable = true)
	public static List<Item__c>getItems(String familyFilter,String typeFilter, String searchTerm){

		String query = 'SELECT Id,Name,Description__c,Type__c,Family__c,' +
				'Image__c,Price__c,AvailableQuantity__c FROM Item__c';

		List<String> conditions = new List<String>(); // список условий where

		//Фильтр по Family
		if(String.isNotBlank(familyFilter)){
			conditions.add('Family__c = :familyFilter');
		}

		//Фильтр по Type
		if(String.isNotBlank(typeFilter)){
			conditions.add('Type--c = :typeFilter')
		}

		//Поиск по Name или Description
		if(String.isNotBlank(searchTerm)){
			String searchPattern = '%'+searchTerm+'%'; // частичное совпадение
			conditions.add('(Name LIKE :searchPattern OR Description__c LIKE :searchPattern)');
		}

		//Собираем условия
		if(!conditions.isEmpty()){
			query+= 'WHERE' + String.join(conditions, ' AND ');
		}

		return Database.query(query);
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getFamilyOptions(){
		List<String> options = new List<String>();

		Schema.DescribeFieldResult fieldResult = Item__c.Family__c.getDescribe();

		List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

		for(Schema.PicklistEntry entry : picklistEntries){
			options.add(entry.getLabel());
		}

		return options;
	}

	@AuraEnabled(chacheable=true)
	public static List<String> getTypeOptions(){
		List<String> options = new List<String>();
		Schema.DescribeFieldResult fieldResult = Item__c.Type__c.getDescribe();
		List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
		for(Schema.PicklistEntry entry : picklistEntries){
			options.add(entry.getLabel());
		}
		return options;
	}
}