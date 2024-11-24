public with sharing class WarehouseSyncSchedule implements Schedulable{
    
    // Method executed by the system when the scheduled job is triggered
    public static void execute(SchedulableContext ctx){
        System.debug('WarehouseSyncSchedule Job Started');
        // Call the method @future to start the synchronization
        System.enqueueJob(new WarehouseCalloutService());
    }

    // Method to schedule the job
    public static void scheduleDailySync(){
        // Define string CRON at 1:00 AM every days
        String cronExpression = '0 0 1 * * ?';
        String jobName = 'Daily Warehouse Sync';

        // Cancel any existing job with the same name to avoid duplicates
        cancelExistingJob(jobName);

        // Schedule the new job
        System.schedule(jobName, cronExpression, new WarehouseSyncSchedule());
        System.debug('Scheduled Daily Warehouse Sync job at 1:00 AM');
    }

    // Method to cancel existing jobs with the same name
    private static void cancelExistingJob(String jobName){
        // Check scheduled jobs
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];

        for(CronTrigger job : existingJobs){
            System.abortJob(job.Id); // Cancel the job
            System.debug('Canceled existing job with ID: ' + job.Id);
        }
    }
}