public class CallOutToCreativeBadger {
    
    public static void getAccounts(){
        Http http = new Http();
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SFDCB/services/apexrest/acctMgmt/');
        request.setMethod('GET');
        
        HttpResponse response = http.send(request);
        System.debug('response ' + response.getBody());
        System.debug('response status ' + response.getStatuscode());
        
        if(response.getStatuscode() == 200){
            AccountWrapper wrapper = (AccountWrapper) JSON.deserialize(response.getBody(), AccountWrapper.class);
            List<Account> accounts = wrapper.accList;
            System.debug(accounts);
            List<Contact> contacts = wrapper.contList;
            System.debug(contacts);
            List<Case> cases = wrapper.caseList;
            System.debug(cases);
            for (Account acc : accounts) {
                System.debug(acc);
                System.debug(acc.Name);
            }
            for (Contact con : contacts) {
                System.debug(con);
            }
            for (Case cas : cases) {
                System.debug(cas);
            }
        }else
        {
            System.debug('Error in integration ' + response.getBody());
        }
    }
    public class AccountWrapper {
        public List<Account> accList;
        public List<Contact> contList;
        public List<Case> caseList;
    }
}