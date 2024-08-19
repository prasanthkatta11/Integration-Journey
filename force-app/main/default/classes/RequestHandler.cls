public with sharing class RequestTriggerHandler {
  public static void onBeforeUpdate(
    List<Request__c> updatedList,
    Map<Id, Request__c> oldMap
  ) {
    // Initialize a map to store reference data categorized by product types
    Map<String, Map<String, String>> categoryMap = new Map<String, Map<String, String>>();

    // Query the reference data and populate the category map
    for (BYT_Reference_Data__c refData : [
      SELECT
        BYT_Request_API_Name__c,
        BYT_Cost_Average__c,
        BYT_Weight_Kg__c,
        Category__c
      FROM BYT_Reference_Data__c
      WITH USER_MODE
    ]) {
      // Ensure the category exists in the map
      if (!categoryMap.containsKey(refData.Category__c)) {
        categoryMap.put(refData.Category__c, new Map<String, String>());
      }

      // Add the API name and its cost and weight as a string with "~" delimiter
      String costWeight =
        (refData.BYT_Cost_Average__c != null
          ? refData.BYT_Cost_Average__c
          : '0') +
        '~' +
        (refData.BYT_Weight_Kg__c != null ? refData.BYT_Weight_Kg__c : '0');
      categoryMap.get(refData.Category__c)
        .put(refData.BYT_Request_API_Name__c, costWeight);
    }

    // Process each updated request record
    for (Request__c req : updatedList) {
      // Check if the request status is changing to 'Delivered'
      if (
        req.Status__c == 'Delivered' &&
        req.Status__c != oldMap.get(req.Id).Status__c
      ) {
        // Initialize a map to store totals for each category
        Map<String, Decimal[]> totalsMap = new Map<String, Decimal[]>();

        // Initialize totals for each category in the totalsMap. This will run based on how many categories are there
        for (String category : categoryMap.keySet()) {
          totalsMap.put(category, new List<Decimal>{ 0, 0 }); // [Total Cost, Total Weight]
        }

        // Iterate over each category in the category map
        for (String category : categoryMap.keySet()) {
          // For each category get respective items, cost and weight
          Map<String, String> fieldMap = categoryMap.get(category);

          for (String fieldAPIName : fieldMap.keySet()) {
            // Check if the request has the field with the specified API name
            if (
              req.getSObjectType()
                .getDescribe()
                .fields.getMap()
                .containsKey(fieldAPIName)
            ) {
              Object fieldValue = req.get(fieldAPIName);

              // If the field has a value, calculate totals
              if (fieldValue != null) {
                Decimal itemCnt = (Decimal) fieldValue;
                // String costWeightString = fieldMap.get(fieldAPIName);
                // List<String> costWeightList = costWeightString.split('~');
                String costWeightString = fieldMap.get(fieldAPIName);
                Decimal cost = Decimal.valueOf(
                  fieldMap.get(costWeightString).split('~')[0]
                );
                Decimal weight = Decimal.valueOf(
                  fieldMap.get(costWeightString).split('~')[1]
                );

                // Update totals for the category
                // totalsMap.get(category)[0] += (cost * itemCnt);
                // totalsMap.get(category)[1] += (weight * itemCnt);

                // Update totals for the category
                Decimal[] totals = totalsMap.get(category);
                totals[0] += (cost * itemCnt);
                totals[1] += (weight * itemCnt);
              }
            }
          }
        }

        // Store the calculated totals back to the request fields
        // req.BYT_Total_Clothing_Cost__c = totalsMap.containsKey('Clothing')
        //   ? totalsMap.get('Clothing')[0]
        //   : 0;
        // req.BYT_Total_Clothing_Weight__c = totalsMap.containsKey('Clothing')
        //   ? totalsMap.get('Clothing')[1]
        //   : 0;

        // req.BYT_Total_Nappies_Cost__c = totalsMap.containsKey('Nappies')
        //   ? totalsMap.get('Nappies')[0]
        //   : 0;
        // req.BYT_Total_Nappies_Weight__c = totalsMap.containsKey('Nappies')
        //   ? totalsMap.get('Nappies')[1]
        //   : 0;

        // req.BYT_Total_Shoes_Cost__c = totalsMap.containsKey('Shoes')
        //   ? totalsMap.get('Shoes')[0]
        //   : 0;
        // req.BYT_Total_Shoes_Weight__c = totalsMap.containsKey('Shoes')
        //   ? totalsMap.get('Shoes')[1]
        //   : 0;
        // Store the calculated totals back to the request fields using dynamic field names
        for (String category : totalsMap.keySet()) {
          Decimal[] totals = totalsMap.get(category);
          req.put('BYT_Total_' + category + '_Cost__c', totals[0]);
          req.put('BYT_Total_' + category + '_Weight__c', totals[1]);
        }
      }
    }
  }
}
