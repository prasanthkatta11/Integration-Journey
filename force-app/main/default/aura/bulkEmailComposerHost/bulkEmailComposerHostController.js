({
  doInit: function (component, event, helper) {
    var recordIds = component.get("v.recordIds");
    console.log("Record IDs:", recordIds);
    var pageRef = {
      type: "standard__component",
      attributes: {
        componentName: "c__bulkEmailComposerHost"
      },
      state: {
        c__recordIds: recordIds
      }
    };
    var navService = component.find("navService");
    navService.navigate(pageRef);
  }
});