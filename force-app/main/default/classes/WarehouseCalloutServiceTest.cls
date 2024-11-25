@isTest
private class WarehouseCalloutServiceTest {

    private static StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    
    @isTest
    static void testGetEquipmentToUpsert() {
        // Set up the mock to simulate the callout response
        mock.setStaticResource('GetEquipmentToUpsert');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associating the mock with the HTTP call
        Test.setMock(HttpCalloutMock.class, mock);

        // Start the test context
        Test.startTest();
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        // Check the records created in Product2
        Integer productCount = [SELECT COUNT() FROM Product2];
        List<Product2> products = [SELECT Id FROM Product2];
        System.debug('1 - TEST PRODUCTOS: ' + products);
        System.assertEquals(22, productCount, 'The product amount expected must be 22.');
    }

    @isTest
    static void testExecuteWithException(){
        Test.setMock(HttpCalloutMock.class, new ExceptionThrowingCalloutMock());

        Test.startTest();
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        List<Product2> products = [SELECT Id FROM Product2];
        System.assertEquals(0, products.size(), 'No products should have been inserted due to the exception.');
    }

    @isTest
    static void testUpsertEquipmentWithDmlException() {
        // Crear datos defectuosos que generen un DmlException
        List<Product2> defectiveProducts = new List<Product2>{
            new Product2(Name = null) // `Name` es un campo obligatorio en Product2
        };

        Test.startTest();
        // Llamar al método directamente
        WarehouseCalloutService.upsertEquipment(defectiveProducts);
        Test.stopTest();

        // Verificar que no se insertaron registros
        List<Product2> products = [SELECT Id FROM Product2];
        System.assertEquals(0, products.size(), 'No deberían haberse insertado productos defectuosos.');
    }
}
