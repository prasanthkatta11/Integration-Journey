/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestPublishPlatformEventCallback {
  @isTest
  static void testFailedEvents() {
    Order_Detail_Demo__e neworder = new Order_Detail_Demo__e();
    neworder.Order_Number__c = '76654';
    neworder.Generate_Invoice__c = true;

    PublishPlatformEventCallback callback = new PublishPlatformEventCallback();
    EventBus.publish(neworder, callback);
    Test.getEventBus().fail();

    List<Task> taskList = [
      SELECT Id, Subject, Description
      FROM Task
      WHERE Subject = 'Platform Event Failed'
    ];

    System.assertEquals(1, 1, 'Task not created');
  }

  @isTest
  static void testSuccessfulEvents() {
    Order_Detail_Demo__e neworder = new Order_Detail_Demo__e();
    neworder.Order_Number__c = '76654';
    neworder.Generate_Invoice__c = true;

    PublishPlatformEventCallback callback = new PublishPlatformEventCallback();
    Test.startTest();
    EventBus.publish(neworder, callback);
    Test.stopTest();

    List<Task> taskList = [
      SELECT Id, Subject, Description
      FROM Task
      WHERE Subject = 'Platform Event Published Successfully'
    ];

    System.assert.areEqual(1, taskList.size(), 'Task created');
  }
}
