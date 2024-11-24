public with sharing class MaintenanceRequestHelper {

    public static void updateWorkOrders(List<Case> updatedCases, Map<Id, Case> oldCaseMap) {
        
        Set<Id> validCaseIds = new Set<Id>();
        List<Case> newMaintenanceCases = new List<Case>();
        Map<Id, Decimal> maintenanceCycles = new Map<Id, Decimal>();
        Map<Id, List<Equipment_Maintenance_Item__c>> equipmentItemsMap = new Map<Id, List<Equipment_Maintenance_Item__c>>();
        
        // Identify closed and validated cases to generate new maintenance cases
        for(Case updatedCase : updatedCases){
            Case oldCase = oldCaseMap.get(updatedCase.Id);
            
            if(oldCase != null && oldCase.Status != 'Closed' && updatedCase.Status == 'Closed' && 
            (updatedCase.Type == 'Repair' || updatedCase.Type == 'Routine Maintenance')){
                validCaseIds.add(updatedCase.Id);
            }
        }

        if(!validCaseIds.isEmpty()){
            // Get maintenance cycles and items related to the valid cases
            List<AggregateResult> results = [
                SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c) cycle
                FROM Equipment_Maintenance_Item__c
                WHERE Maintenance_Request__c IN :validCaseIds
                GROUP BY Maintenance_Request__c
            ];

            for(AggregateResult result : results){
                maintenanceCycles.put((Id) result.get('Maintenance_Request__c'), (Decimal) result.get('cycle'));

            }

            List<Equipment_Maintenance_Item__c> equipmentItems = [
                SELECT Id, Equipment__c, Quantity__c, Maintenance_Request__c
                FROM Equipment_Maintenance_Item__c
                WHERE Maintenance_Request__c IN :validCaseIds
            ];

            for(Equipment_Maintenance_Item__c item : equipmentItems){
                if(!equipmentItemsMap.containsKey(item.Maintenance_Request__c)){
                    equipmentItemsMap.put(item.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c>());
                }
                equipmentItemsMap.get(item.Maintenance_Request__c).add(item);
            }

            // Create new Maintenance Cases
            for(Case updatedCase : updatedCases){

                if(validCaseIds.contains(updatedCase.Id)){
                    Case newCase = new Case(
                        Type = 'Routine Maintenance',
                        Subject = 'Routine checkup in the future',
                        Date_Reported__c = Date.today(),
                        Vehicle__c = updatedCase.Vehicle__c,
                        ParentId = updatedCase.Id // Associate the new case to the original updated case 
                    );
    
                    if(maintenanceCycles != null && maintenanceCycles.containsKey(updatedCase.Id)){
                        newCase.Date_Due__c = Date.today().addDays((Integer) maintenanceCycles.get(updatedCase.Id));
                    }
    
                    newMaintenanceCases.add(newCase);
                }
            }

            if(!newMaintenanceCases.isEmpty()){
                insert newMaintenanceCases;

                // Clone the maintenance items associated to the new cases
                List<Equipment_Maintenance_Item__c> clonedItems = new List<Equipment_Maintenance_Item__c>();
                
                for(Case newCase : newMaintenanceCases){
                
                    if(equipmentItemsMap != null && equipmentItemsMap.containsKey(newCase.ParentId)){
                        
                        for(Equipment_Maintenance_Item__c oldItem : equipmentItemsMap.get(newCase.ParentId)){
                            Equipment_Maintenance_Item__c newItem = oldItem.clone();
                            newItem.Maintenance_Request__c = newCase.Id;
                            clonedItems.add(newItem);
                        }
                    }
                }

                if(!clonedItems.isEmpty()){
                    insert clonedItems;
                }
            }
        }
    }
}