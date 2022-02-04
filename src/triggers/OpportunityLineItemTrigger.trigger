trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert,before update,after update) {
    
    if(Trigger.isBefore && Trigger.isInsert){
        OpportunityLineItemHandler.onBeforeInsert(Trigger.new);
    }
    else if(Trigger.isBefore && Trigger.isUpdate){
        OpportunityLineItemHandler.onBeforeUpdate(Trigger.new,Trigger.oldMap);
    }
    else if(Trigger.isAfter){
         if(Trigger.isInsert||Trigger.isUpdate){
           CLDLY_ClassificationDetailsCtrl.updateOppClassificationDetails(Trigger.new);
            if(Trigger.isUpdate){
               OpportunityItemTriggerControl__mdt[] trigerControl = [SELECT Id, IsActive__c,DeveloperName FROM OpportunityItemTriggerControl__mdt
                     WHERE DeveloperName = 'Update_Project_Fields_From_OppItem' LIMIT 1];
                     
                     system.debug('++++++++++++++++++++++++++++++'+trigerControl.size());
                if(trigerControl.size()>0 && trigerControl[0].IsActive__c == true) {
                    
                     CLDLY_UpdateProjectFieldHandler.OnAfterUpdateNetsuiteSOLineId(Trigger.new,Trigger.oldMap);
                     
                }
                
            }  
        }
    }
}