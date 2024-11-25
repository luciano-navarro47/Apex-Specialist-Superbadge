public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    // External system URL
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    // Main method that will be executed to enqueue the job
    public void execute(QueueableContext ctx){
        System.debug('WarehouseCalloutService - Queueble job started');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(WAREHOUSE_URL);
        req.setMethod('GET');

        try {
            HttpResponse res = http.send(req);

            if(res != null && res.getStatusCode() == 200){
                System.debug('STATUS CODE RES: ' + res.getStatusCode());
                System.debug('RES: ' + res.getBody());
                List<Product2> equipmentToUpsert = parseWarehouseData(res.getBody());
                upsertEquipment(equipmentToUpsert);
            } else {
                System.debug('Error: Failed to fetch data. Status code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception during callout: ' + e.getMessage());
        }
    }

    // Method to analize the JSON's data and convert into Salesforce records
    @TestVisible
    private static List<Product2> parseWarehouseData(String responseBody){
        List<Product2> equipments = new List<Product2>();
        List<Object> jsonData = (List<Object>) JSON.deserializeUntyped(responseBody);

        for(Object obj : jsonData){
            Map<String,Object> record = (Map<String,Object>) obj;

            Product2 equipment = new Product2();
            equipment.Replacement_Part__c = (Boolean) record.get('replacement');
            equipment.Cost__c = (Integer) record.get('cost');
            equipment.Name = (String) record.get('name');
            equipment.Current_Inventory__c = (Integer) record.get('quantity');
            equipment.Lifespan_Months__c = (Integer) record.get('lifespan');
            equipment.Maintenance_Cycle__c = (Integer) record.get('maintenanceperiod');
            equipment.Warehouse_SKU__c = (String) record.get('sku');

            equipments.add(equipment);
        }

        return equipments;
    }

    // Method to upsert the Salesforce records
    @TestVisible
    private static void upsertEquipment(List<Product2> equipments){

        if(!equipments.isEmpty()){
            try {
                upsert equipments;
                System.debug('Successfully upserted ' + equipments.size() + ' records.');
            } catch (DmlException e) {
                System.debug('Error at the equipments´ upsert: ' + e.getMessage());
            }
        } else {
            System.debug('No equipment data to upsert.');
        }
    }
}