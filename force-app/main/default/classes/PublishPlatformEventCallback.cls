public with sharing class PublishPlatformEventCallback implements EventBus.EventPublishSuccessCallback, EventBus.EventPublishFailureCallback {
  public void onSuccess(EventBus.SuccessResult result) {
    List<String> eventUUIds = result.getEventUuids();
    CreateTask(eventUUIds, true);
  }

  public void onFailure(EventBus.FailureResult result) {
    List<String> eventUUIds = result.getEventUuids();
    CreateTask(eventUUIds, false);
  }

  public void CreateTask(List<String> eventUUIds, Boolean isSuccess) {
    String UUIDString = '';
    for (String eventId : eventUUIds) {
      UUIDString = UUIDString + eventId + ' ';
    }
    Task taskDetail = new Task();
    //Platform Event Publish Successful
    if (isSuccess) {
      taskDetail.Subject = 'Platform Event Published Successfully';
      taskDetail.Description =
        'Total Platform Events Published: ' +
        eventUUIds.size() +
        '\n' +
        UUIDString;
    } else {
      taskDetail.Subject = 'Platform Event Failed';
      taskDetail.Description =
        'Platform Event Publish Failed: ' +
        eventUUIds.size() +
        '\n' +
        UUIDString;
    }
    taskDetail.ActivityDate = Date.today();
    User userdetail = [
      SELECT Id, Name
      FROM User
      WHERE UserName = 'prasanthkatta11@empathetic-raccoon-pvq8ld.com'
    ];
    taskDetail.OwnerId = userdetail.Id;

    try {
      insert taskDetail;
    } catch (Exception e) {
      System.debug('Task Insert failed: ' + e.getMessage());
    }
  }
}
