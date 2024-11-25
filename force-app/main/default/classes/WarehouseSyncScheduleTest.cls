@isTest
public with sharing class WarehouseSyncScheduleTest {
    // implement scheduled test code here

    @isTest
    static void testScheduleDailySync(){
        
        String existingJobName = 'Daily Warehouse Sync';
        System.schedule(existingJobName, '0 0 1 * * ?', new WarehouseSyncSchedule());

        Test.startTest();
        WarehouseSyncSchedule.scheduleDailySync();

        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :existingJobName
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'There must be a scheduled job');
        System.assertEquals('WAITING', scheduledJobs[0].State, 'The scheduled job must be in a "WAITING" state');

        Test.stopTest();
    }

    @isTest
    static void testExecuteMethod(){
        Test.startTest();

        WarehouseSyncSchedule.execute(null);

        Test.stopTest();

        List<AsyncApexJob> asyncJobs = [
            SELECT Id, JobType, Status
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
        ];

        System.assertEquals(1, asyncJobs.size(), 'There must be a queued job');
        System.assertEquals('Completed', asyncJobs[0].Status, 'The job must be in "Completed" status.');
    }
}