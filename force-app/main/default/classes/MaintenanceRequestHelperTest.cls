@isTest
public with sharing class MaintenanceRequestHelperTest {

    @isTest
    static void testTriggerCallsUpdateWorkOrders() {
        // Create a test vehicle
        Vehicle__c testVehicle = new Vehicle__c(Name = 'Test Vehicle');
        insert testVehicle;

        // Step 1: Set up initial case with 'New' status and 'Repair' type
        Case testCase = new Case(
            Status = 'New',
            Type = 'Repair',
            Subject = 'Test Repair Case',
            Vehicle__c = testVehicle.Id 
        );
        insert testCase;

        // Create a test equipment
        Product2 testEquipment = new Product2(
            Name='TestEquipment',
            IsActive=true,
            Replacement_Part__c=true,
            Maintenance_Cycle__c = 30
        );
        insert testEquipment;

        // Step 2: Create a maintenance item related to the case
        Equipment_Maintenance_Item__c maintenanceItem = new Equipment_Maintenance_Item__c(
            Equipment__c = testEquipment.Id,
            Maintenance_Request__c = testCase.Id,
            Quantity__c = 2
        );
        insert maintenanceItem;

        // Step 3: Simulate updating the case to the 'Closed' status
        testCase.Status = 'Closed';
        update testCase; // This activates the trigger!

        // Step 4: Validate that a new case of type 'Routine Maintenance' has been created
        List<Case> maintenanceCases = [
            SELECT Id, Type, Subject, ParentId, Date_Due__c
            FROM Case
            WHERE ParentId = :testCase.Id
        ];

        Case newCase = maintenanceCases[0];
        System.assertEquals(1, maintenanceCases.size(), 'Debe crearse un caso hijo de mantenimiento.');
        System.assertEquals('Routine Maintenance', newCase.Type, 'El nuevo caso debe ser de tipo Routine Maintenance.');
        System.assertEquals(testCase.Id, newCase.ParentId, 'El nuevo caso debe estar relacionado con el caso original.');
        System.assertNotEquals(null, newCase.Date_Due__c, 'El nuevo caso debe tener una fecha de vencimiento configurada.');

        // Step 5: Validate that the maintenance items have been cloned
        List<Equipment_Maintenance_Item__c> clonedItems = [
            SELECT Id, Maintenance_Request__c, Quantity__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c = :newCase.Id
        ];
        System.assertEquals(1, clonedItems.size(), 'Debe clonarse un elemento de mantenimiento para el nuevo caso.');
        System.assertEquals(maintenanceItem.Quantity__c, clonedItems[0].Quantity__c, 'El elemento de mantenimiento clonado debe conservar la misma cantidad.');
    }

    @isTest
    static void testTriggerDoesNotFireForInvalidCase() {
        // Create an initial case
        Case testCase = new Case(
            Subject = 'Invalid Maintenance Case',
            Status = 'New',
            Type = 'Repair'
        );
        insert testCase;

        testCase.Status = 'In-Progress'; // Does not change to 'closed'
        update testCase; // This fires the trigger, but it shouldn't do anything

        // Verify that no new child cases haven been created
        List<Case> maintenanceCases = [SELECT Id FROM Case WHERE ParentId = :testCase.Id];
        System.assertEquals(0, maintenanceCases.size(), 'No maintenance cases should be created');
    }

    @isTest
    static void testHandles300MaintenanceRequests(){
        // This test confirms that 300 maintenance request were successfully processed
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 300; i++) {
            testCases.add(new Case(
                Type='Repair',
                Status='New',
                Subject='Test Case'
            ));
        }

        insert testCases;

        for (Case newCase : testCases) {
            newCase.Status='Closed';
        }

        update testCases; // Fire the trigger

        List<Case> maintenanceRequest = [
            SELECT Id, Status, Type, Subject, Date_Due__c
            FROM Case
            WHERE ParentId IN :testCases
        ];

        Integer expectedNumber = 300;
        System.assertEquals(expectedNumber, maintenanceRequest.size());
    }
}
