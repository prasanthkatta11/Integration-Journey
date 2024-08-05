public with sharing class PublishPlatformEvent {
  public static void PublishPlatformEventDemo() {
    List<Order_Detail_Demo__e> orderDetailListEvent = new List<Order_Detail_Demo__e>();

    orderDetailListEvent.add(
      new Order_Detail_Demo__e(
        Order_Number__c = '76654',
        Generate_Invoice__c = true
      )
    );
    orderDetailListEvent.add(
      new Order_Detail_Demo__e(
        Order_Number__c = '76644',
        Generate_Invoice__c = false
      )
    );
    orderDetailListEvent.add(
      new Order_Detail_Demo__e(
        Order_Number__c = '73454',
        Generate_Invoice__c = true
      )
    );

    PublishPlatformEventCallback callback = new PublishPlatformEventCallback();
    List<Database.SaveResult> resultList = EventBus.publish(
      orderDetailListEvent,
      callback
    );

    for (Database.SaveResult resultItem : resultList) {
      if (resultItem.isSuccess()) {
        System.debug('Successfully published event.');
      } else {
        List<Database.Error> errorList = resultItem.getErrors();
        for (Database.Error error : errorList) {
          System.debug(
            'Error returned: ' +
              error.getStatusCode() +
              ' - ' +
              error.getMessage()
          );
        }
      }
    }
  }
}
