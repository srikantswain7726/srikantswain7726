/**
*Author : Nagaraju G
Date : 16/07/2021
*Description : This class used for update project field from Opportunity field value
*
*/
public with sharing class CLDLY_ProjectTriggerHandler{
    
    /**
* This method is used for update project fields (pse__Project_Manager__c),start date & end date
from Opportunity field(PS_Primary_Manager__c) value
* */
    public static void onBeforeInsert(List<pse__Proj__c> projectList) { 
        List<Id>opportunityIds=new List<Id>();
        List<Id>oppliIds=new List<Id>();
        set<Id>accountIds=new set<Id>();
        Map<String,Opportunity> OpportunityUpdateMap = new Map<String,Opportunity>();
        Map<Id,OpportunityLineItem> parentOPLIsMap=new Map<Id,OpportunityLineItem>();
        Map<String,Contact>contactMap=new Map<String,Contact>();
        system.debug('===handler===='+projectList);
        for(pse__Proj__c prj:projectList){
            opportunityIds.add(prj.pse__Opportunity__c);
            oppliIds.add(prj.OLI_ID__c);
        }
        
        if(!opportunityIds.isEmpty()){
            for(Opportunity oppr:[SELECT id,Name,AccountId,PS_Primary_Manager__c,
                                  PS_Primary_Manager__r.FirstName,PS_Primary_Manager__r.Name FROM
                                  Opportunity WHERE Id IN:opportunityIds]){
                                      OpportunityUpdateMap.put(Oppr.id,Oppr);
                                      accountIds.add(oppr.AccountId);
                                  }
        }
        contactMap=getContacts(accountIds);// get all contacts map
        parentOPLIsMap=getOpportunityLineItem(oppliIds);
        for(pse__Proj__c prj:projectList){
            if(prj.pse__Opportunity__c<>NULL){
                Opportunity oppRec=OpportunityUpdateMap.get(prj.pse__Opportunity__c);
                contact con=contactMap.get(oppRec.AccountId+'-'+oppRec.PS_Primary_Manager__r.Name);
                system.debug('===con===='+con);
                if(con<>NULL)
                    prj.pse__Project_Manager__c=con.Id;// Mapped contactid 
                //else 
                //prj.pse__Project_Manager__c='';
            }
            system.debug('===prj.OLI_ID__c===='+prj.OLI_ID__c);
            if(prj.OLI_ID__c<>NULL){ // Mapped subscription sd & ed from opportunity line iteam 
                OpportunityLineItem parentOPLI=parentOPLIsMap.get(prj.OLI_ID__c);
                if(parentOPLI.Product2.Project_Template__c<>NULL) // Mapped pse__Planned_Hours__c from opportunity line iteam
                    prj.pse__Planned_Hours__c=parentOPLI.Quantity * parentOPLI.Product2.Project_Template__r.pse__Planned_Hours__c;
                    prj.pse__Include_In_Forecasting__c = parentOPLI.Product2.Project_Template__r.pse__Include_In_Forecasting__c ;
                    prj.pse__Recognition_Method__c = parentOPLI.Product2.Project_Template__r.pse__Recognition_Method__c ;
                    prj.Sku_code__c = parentOPLI.ProductCode;
                    prj.Number_of_Seats__c = parentOPLI.Quantity;
                    system.debug('------------------------------------>');
                system.debug('===prj.OLI_ID__c===='+prj.pse__Planned_Hours__c);
            }
        }
    }
    
    public static Map<String,Contact>getContacts(set<Id>accountIds){
        Map<String,Contact>contactMap=new Map<String,Contact>();
        for(contact con:[SELECT Id,Name,AccountId,FirstName FROM Contact WHERE AccountId IN:accountIds]){
            string key=con.AccountId+'-'+con.Name;
            //system.debug('===key===='+key);
            contactMap.put(key,con);
        }
        //system.debug('===contactMap===='+contactMap);
        return contactMap;
    }
    
    /**
* getting Subscription_Start_Date__c,f_Subscription_End_Date__c from Opportunity Line Iteam 
* */
    public static Map<Id, OpportunityLineItem> getOpportunityLineItem(List<Id>opliId){
        Map<Id,OpportunityLineItem> parentOPLIsMap=new Map<Id,OpportunityLineItem>();
        parentOPLIsMap = new Map<Id, OpportunityLineItem>([SELECT id,f_Subscription_Start_Date__c, Netsuite_Line_Item_Id__c,
                                                           f_Subscription_End_Date__c, Quantity,f_ACV__c,ProductCode,
                                                           Product2.Project_Template__r.pse__Include_In_Forecasting__c,
                                                           Product2.Project_Template__r.pse__Recognition_Method__c,
                                                           Opportunity.CloseDate,
                                                           Product2.Project_Template__r.pse__Planned_Hours__c FROM OpportunityLineItem 
                                                           WHERE ID IN :opliId]);
        
        return parentOPLIsMap;
    }
    
    public static void updateProjectDates(List<pse__Proj__c>projectList){ 
        Map<Id,OpportunityLineItem> parentOPLIsMap=new Map<Id,OpportunityLineItem>();
        pse__Proj__c[] projUpdates = new pse__Proj__c[] {};
            pse__Proj__c[] projUpdatesList = new pse__Proj__c[] {};
                List<Id>oppliIds=new List<Id>();
        for(pse__Proj__c prj:projectList){
            oppliIds.add(prj.OLI_ID__c);
        }
        //oppliIds.add('00k6u000003Jg8yAAC');
        system.debug('=oppliIds==='+oppliIds);
        parentOPLIsMap=getOpportunityLineItem(oppliIds);
        for (pse__Proj__c prj: projectList) {           
            OpportunityLineItem parentOPLI=parentOPLIsMap.get(prj.OLI_ID__c); //'00k6u000003Jg8yAAC');//
            system.debug('=parentOPLI==='+parentOPLI);
            if(parentOPLI<>null)
                projUpdates.add(new pse__Proj__c(Id = prj.Id,
                                                 pse__Start_Date__c=parentOPLI.f_Subscription_Start_Date__c<>NULL?parentOPLI.f_Subscription_Start_Date__c:null,
                                                 pse__End_Date__c= parentOPLI.f_Subscription_End_Date__c<>null?parentOPLI.f_Subscription_End_Date__c:null));
        }
        
        for (pse__Proj__c prj: projectList) {
            if(prj.pse__Start_Date__c<>NULL && prj.pse__End_Date__c<>NULL)
                projUpdatesList.add(prj);
        }
        system.debug('=projUpdates==='+projUpdatesList);
        if(projUpdatesList.size()>0)
            update projUpdates;
    }
    
    // For update Project fields(Netsuite_SO_Number__c,Netsuite_SO_Id__c,Netsuite_SO_Line_Id__c) with OPLI and order fields(NetSuite_Order_Number__c,Netsuite_Id__c) values 
    public static void updateNetsuiteFileds(List<pse__Proj__c> projectList) {
        List<Id>opportunityIds=new List<Id>();
        Map<Id,Order>netsuiteOrderMap=new  Map<Id,Order>();
        List<Id>oppliIds=new List<Id>();
        Map<Id,OpportunityLineItem> parentOPLIsMap=new Map<Id,OpportunityLineItem>();

        for(pse__Proj__c prj:projectList){
            if(prj.pse__Opportunity__c<>null)
                opportunityIds.add(prj.pse__Opportunity__c);
            if(prj.OLI_ID__c<>null)
                oppliIds.add(prj.OLI_ID__c);
        }
        
         //system.debug('===opportunityIds==='+opportunityIds);
        // system.debug('===oppliIds==='+oppliIds);
          
        if(opportunityIds.size()>0){
            for(Order orderObj:[SELECT Id,OpportunityId,Cloud_Primary_Contact__c,SBQQ__Quote__c,NetSuite_Order_Number__c,
                                Netsuite_Id__c,SBQQ__Quote__r.Name,SBQQ__Quote__r.SBQQ__Primary__c FROM Order
                                WHERE OpportunityId IN:opportunityIds]){
                                    system.debug('===newOrderMap==='+orderObj.SBQQ__Quote__r.SBQQ__Primary__c);
                                    if(orderObj.SBQQ__Quote__r.SBQQ__Primary__c)
                                        netsuiteOrderMap.put(orderObj.OpportunityId,orderObj);    
                                }
        }
        //system.debug('===newOrderMap==='+netsuiteOrderMap);
        if(oppliIds<>null)
            parentOPLIsMap=getOpportunityLineItem(oppliIds);
        //system.debug('===parentOPLIsMap==='+parentOPLIsMap);
        for(pse__Proj__c prjObject:projectList){
            if(!parentOPLIsMap.isEmpty() && prjObject.OLI_ID__c<>null){
                 prjObject.Netsuite_SO_Line_Id__c= parentOPLIsMap.get(prjObject.OLI_ID__c)<>null ? parentOPLIsMap.get(prjObject.OLI_ID__c).Netsuite_Line_Item_Id__c:'';
                 //system.debug('===orderRec==='+prjObject.Netsuite_SO_Line_Id__c);
            }
            if(netsuiteOrderMap<>NULL && !netsuiteOrderMap.isEmpty()){
                Order orderRec=netsuiteOrderMap.get(prjObject.pse__Opportunity__c);
               //system.debug('===orderRec==='+orderRec);
                if(orderRec<>null){
                    prjObject.Netsuite_SO_Number__c=orderRec.NetSuite_Order_Number__c<>null?orderRec.NetSuite_Order_Number__c:null;
                    prjObject.Netsuite_SO_Id__c =orderRec.Netsuite_Id__c<>null?orderRec.Netsuite_Id__c:null;
                }
            }
            
        }
      }
}