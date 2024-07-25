import { LightningElement, track, api } from "lwc";
import LISTALLMESSAGES from "@salesforce/apex/WhatsAppLwcHelperClass.listAllMessages";
import SENDTEXTMESSAGE from "@salesforce/apex/WhatsAppLwcHelperClass.sendTextMessage";
import GETINCOMINGMESSAGE from "@salesforce/apex/WhatsAppLwcHelperClass.getIncomingMessage";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import GETCUSTOMERPHONEDYNAMICALLY from "@salesforce/apex/WhatsAppLwcHelperClass.getCustomerPhoneDynamically";

export default class WhatsAppChatComponent extends LightningElement {
  @api recordId;
  @api objectApiName;

  @track messages = [];
  @track error;

  showSpinner = false;
  showChat = false;
  showPhoneAndButton = true;
  phone;
  messageText = "";

  queryString;

  channelName = "/event/WhatsApp_Media_Event__e";

  subscription = {};

  connectedCallback() {
    console.log("Connected Callback - RecordId:", this.recordId);
    console.log("Connected Callback - ObjectApiName:", this.objectApiName);

    if (this.objectApiName === "Account") {
      this.queryString = `SELECT Id, Phone from Account WHERE Id = '${this.recordId}'`;
    } else if (this.objectApiName === "Contact") {
      this.queryString = `SELECT Id, Phone from Contact WHERE Id = '${this.recordId}'`;
    } else if (this.objectApiName === "Lead") {
      this.queryString = `SELECT Id, Phone from Lead WHERE Id = '${this.recordId}'`;
    } else if (this.objectApiName === "Opportunity") {
      this.queryString = `SELECT Id, Phone from Opportunity WHERE Id = '${this.recordId}'`;
    } else if (this.objectApiName === "Case") {
      this.queryString = `SELECT Id, Phone from Case WHERE Id = '${this.recordId}'`;
    } else if (this.objectApiName === "WhatsApp_Message__c") {
      this.queryString = `SELECT Id, Customer_Phone__c from WhatsApp_Message__c WHERE Id = '${this.recordId}'`;
    }

    if (this.recordId && this.objectApiName) {
      this.handleCustomerPhoneDynamically();
    } else {
      console.error("RecordId or objectApiName is missing.");
    }

    this.handleSubscribe();
    // Register error listener
    this.registerErrorListener();
  }

  handleCustomerPhoneDynamically() {
    GETCUSTOMERPHONEDYNAMICALLY({
      query: this.queryString
    })
      .then((response) => {
        this.phone =
          this.objectApiName === "WhatsApp_Message__c"
            ? response.Customer_Phone__c
            : response.Phone;

        console.log("Phone number set to:", this.phone);
        console.log(
          "🚀 ~ WhatsAppChatComponent ~ .then ~ this.recordId:",
          this.recordId
        );
        this.handleListAllMessages();
      })
      .catch((error) => {
        this.error = error;
        console.log(
          "🚀 ~ WhatsAppChatComponent ~ handleCustomerPhoneDynamically ~ error:",
          error
        );
      })
      .finally(() => {
        console.log(
          "🚀 ~ WhatsAppChatComponent ~ handleCustomerPhoneDynamically ~ finally:"
        );
      });
  }

  disconnectedCallback() {
    console.log("DisconnectedCallback triggered");
    // Unsubscribe from the channel
    unsubscribe(this.subscription, (response) => {
      console.log("Unsubscribe response: ", JSON.stringify(response));
    });
    // Unregister error listener
    onError((error) => {
      console.log("Error: ", JSON.stringify(error));
    });
  }

  registerErrorListener() {
    onError((error) => {
      console.log("Error: ", JSON.stringify(error));
    });
  }

  // Handles subscribe button click
  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = (response) => {
      console.log("WhatsApp Webhook: ", JSON.stringify(response));
      let data = response.data.payload;
      let messageId = data.RecordId__c;
      let customerPhone = data.Customer_Phone_Number__c;
      if (this.phone === customerPhone) {
        //Make Apex call
        GETINCOMINGMESSAGE({
          recordId: messageId,
          customerPhone: customerPhone
        })
          .then((result) => {
            console.log("GETINCOMINGMESSAGE result:", result);
            this.messages = [...this.messages, result];
            console.log(
              "🚀 ~ WhatsAppChatComponent ~ .then ~ this.messages:",
              this.messages
            );
          })
          .catch((error) => {
            this.error = error;
            this.showChat = false;
          })
          .finally(() => {
            this.chatArea();
            this.showSpinner = false;
          });
      }
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

  chatArea() {
    let chatArea = this.template.querySelector(".chatArea");
    if (chatArea) {
      chatArea.scrollTop = chatArea.scrollHeight;
    }
  }

  //Get the agent Name and return the initials
  getInitials(name) {
    if (!name) return "";
    const names = name.split(" ");
    if (names.length === 1) {
      return names[0].charAt(0).toUpperCase();
    }
    return names.map((n) => n.charAt(0).toUpperCase()).join("");
  }

  handlePhoneChange(event) {
    event.preventDefault();
    this.phone = event.target.value;
    console.log(
      "🚀 ~ WhatsAppChatComponent ~ handlePhoneChange ~ this.phone:",
      this.phone
    );
  }

  handleChat(event) {
    if (event) {
      event.preventDefault();
    }
    if (this.handleValidate()) {
      this.handleListAllMessages();
    }
  }

  handleListAllMessages() {
    this.showSpinner = true;
    LISTALLMESSAGES({ customerPhone: this.phone })
      .then((result) => {
        console.log("🚀 ~ Validation passed, calling LISTALLMESSAGES");

        this.messages = result.map((item) => {
          return {
            ...item,
            agentInitials: item.Outgoing__c
              ? this.getInitials(item.Agent_Name__c)
              : ""
          };
        });
        this.showChat = true;
        this.showPhoneAndButton = false;
      })
      .catch((error) => {
        this.error = error;
        this.showChat = false;
        this.showPhoneAndButton = true;
        console.log(error);
      })
      .finally(() => {
        this.chatArea();
        this.showSpinner = false;
        this.setUpChatMessage();
      });
  }

  renderedCallback() {
    if (this.isRendered) {
      return;
    }
    this.isRendered = true;
    this.setUpChatMessage();
  }

  setUpChatMessage() {
    console.log("Setting up chat message event listener");
    let chatInput = this.template.querySelector(".chat-Input");
    let phoneInputScreen = this.template.querySelector(".phone-Input");

    if (chatInput) {
      chatInput.addEventListener("keydown", (event) => {
        console.log(`Enent handler added`);
        if (event.key === "Enter") {
          event.preventDefault();
          this.handleSendMessage();
        }
      });
    }

    if (phoneInputScreen) {
      phoneInputScreen.addEventListener("keydown", (event) => {
        console.log(`Enent handler added`);
        if (event.key === "Enter") {
          event.preventDefault();
          this.handleChat();
        }
      });
    }
  }

  handleSendMessage() {
    console.log("Handle send message triggered");
    if (this.handleValidate()) {
      console.log("Validation passed, calling SENDTEXTMESSAGE");
      this.showSpinner = true;
      SENDTEXTMESSAGE({
        messageContent: this.messageText,
        toPhoneNumber: this.phone
      })
        .then((result) => {
          console.log("SENDTEXTMESSAGE result:", result);
          this.messages = [...this.messages, result];
          console.log(
            "🚀 ~ WhatsAppChatComponent ~ .then ~ this.messages:",
            this.messages
          );
        })
        .catch((error) => {
          this.error = error;
          this.showChat = false;
        })
        .finally(() => {
          this.chatArea();
          this.messageText = "";
          this.showSpinner = false;
        });
    }
  }

  handleChange(event) {
    event.preventDefault();
    this.messageText = event.target.value;
    console.log("Message text changed:", this.messageText);
  }

  handleValidate() {
    const phoneInput = this.template.querySelector("lightning-input");
    // If there is no phone input, return true (assuming this is not expected)
    if (!phoneInput) {
      return true;
    }

    // If the phone number is invalid, set custom validity and return false
    if (this.phone && !this.isValidAustralianPhoneNumber(this.phone)) {
      phoneInput.setCustomValidity(
        "Please enter a valid Australian phone number"
      );
      phoneInput.reportValidity();
      return false;
    }

    // If the phone number is valid, clear the custom validity
    phoneInput.setCustomValidity("");

    return [...this.template.querySelectorAll("lightning-input")].reduce(
      (validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
      },
      true
    );
  }

  isValidAustralianPhoneNumber(phone) {
    // Regular expression to match Australian phone numbers
    const australianPhonePattern = /^(\+61|61)?\d{9}$/;
    const isValid = australianPhonePattern.test(phone);
    console.log("Is phone number valid:", isValid);
    return isValid;
  }

  handleAnotherChat() {
    this.showPhoneAndButton = true;
    this.showChat = false;
    this.phone = "";
    this.messageText = "";
    this.messages = [];
    this.isRendered = false;
  }
}
