import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { LightningElement, api, wire } from "lwc";
import CASE_OBJECT from "@salesforce/schema/Case";
import STATUS_FIELD from "@salesforce/schema/Case.Status";
import CASEID_FIELD from "@salesforce/schema/Case.Id";
import {
  getRecord,
  updateRecord,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  subscribe,
  unsubscribe,
  onError,
  setDebugFlag,
  isEmpEnabled
} from "lightning/empApi";

export default class CaseProgressIndicator extends LightningElement {
  @api recordId;
  statusOptions = [];
  currentStatus = "";
  subscription = {};
  channelName = "/event/Case_Details__e";

  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  caseObjectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$caseObjectInfo.data.defaultRecordTypeId",
    fieldApiName: STATUS_FIELD
  })
  caseStatusPicklistValues({ error, data }) {
    if (data) {
      this.statusOptions = data.values;
      console.log(
        "🚀 ~ CaseProgressIndicator ~ caseStatusPicklistValues ~ data:",
        data
      );
    } else if (error) {
      console.log(
        "🚀 ~ CaseProgressIndicator ~ caseStatusPicklistValues ~ error:",
        error
      );
    }
  }

  //get current status of the record
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [STATUS_FIELD]
  })
  getRecordStatusOutput({ data, error }) {
    if (data) {
      console.log(
        "🚀 ~ CaseProgressIndicator ~ getRecordStatusOutput ~ data:",
        data
      );
      this.currentStatus = data.fields.Status.value;
    } else if (error) {
      console.log(
        "🚀 ~ CaseProgressIndicator ~ getRecordStatusOutput ~ error:",
        error
      );
    }
  }

  handleStepClick(event) {
    event.preventDefault();
    if (event) {
      const newStatus = event.target.dataset.value; // Get the new status from the clicked step
      if (newStatus && newStatus !== this.currentStatus) {
        this.updateCaseStatus(newStatus);
      }
    }
  }

  updateCaseStatus(newStatus) {
    const fields = {};
    fields[STATUS_FIELD.fieldApiName] = newStatus;
    fields[CASEID_FIELD.fieldApiName] = this.recordId;

    const recordInput = { fields };

    updateRecord(recordInput)
      .then(() => {
        this.currentStatus = newStatus;
        this.showToast(
          "Success",
          "Case status updated successfully",
          "success"
        );
      })
      .catch((error) => {
        this.error = "Error updating record";
        console.error("Error updating record:", error);
        this.showToast("Error", "Error updating case status", "error");
      });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }

  connectedCallback() {
    this.handleSubscribe();
    // Register error listener
    this.registerErrorListener();
  }

  disconnectedCallback() {
    // Unsubscribe from the event channel
    this.handleUnsubscribe();
    // Unregister error listener
    this.unregisterErrorListener();
  }

  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = (response) => {
      console.log("New message received: ", JSON.stringify(response));
      // Response contains the payload of the new message received
      this.handleResponse(response);
    };

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log(
        "Subscription request sent to: ",
        JSON.stringify(response.channel)
      );
      this.subscription = response;
    });
  }

  async handleResponse(response) {
    let responseCaseId = response.data?.payload?.Case_Id__c;
    console.log(
      "🚀 ~ CaseProgressIndicator ~ handleResponse ~ responseCaseId:",
      responseCaseId
    );

    let responseCaseStatus = response.data?.payload?.Case_Status__c;
    console.log(
      "🚀 ~ CaseProgressIndicator ~ handleResponse ~ responseCaseStatus:",
      responseCaseStatus
    );

    const fields = {};

    fields[STATUS_FIELD.fieldApiName] = responseCaseStatus;
    fields[CASEID_FIELD.fieldApiName] = responseCaseId;

    let recordInput = { fields };
    try {
      await updateRecord(recordInput);
      this.currentStatus = responseCaseStatus;
      await notifyRecordUpdateAvailable({ recordId: responseCaseId });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: `Case status updated successfully to ${responseCaseStatus}`,
          variant: "success"
        })
      );
    } catch (error) {
      console.log("Error updating record:", error);
      this.showToast("Error", "Error updating with platform Event", "error");
    }
  }

  // Handles unsubscribe button click
  handleUnsubscribe() {
    // Invoke unsubscribe method of empApi
    unsubscribe(this.subscription, (response) => {
      console.log("unsubscribe() response: ", JSON.stringify(response));
      // Response is true for successful unsubscribe
    });
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }
}
