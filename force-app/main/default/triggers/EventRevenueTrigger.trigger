trigger EventRevenueTrigger on Ticket__c (after insert, after update, after delete, after undelete) {
    Set<Id> eventIds = new Set<Id>();
    if(Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete){
        for(Ticket__c ticket : Trigger.new){
            if(ticket.Event__c != null){
                eventIds.add(ticket.Event__c);
            }
        }
    }
    if(Trigger.isDelete){
        for(Ticket__c ticket : Trigger.old){
            if(ticket.Event__c != null){
                eventIds.add(ticket.Event__c);
            }
        }
    }
    List<Event__c> updateEvents = new List<Event__c>();
    for(Id eventId : eventIds){
        List<Ticket__c> paidTickets = [SELECT Total_Ticket_Price__c, Payment_Status__c FROM Ticket__c Where Event__c = :eventIds AND Payment_Status__c = 'Paid'];
        
        Decimal totalRevenue = 0 ;
      
        for(Ticket__c ticket : paidTickets){
           totalRevenue += ticket.Total_Ticket_Price__c != null ? ticket.Total_Ticket_Price__c : 0;
        }
        updateEvents.add(new Event__c(Id = eventId, Event_Revenue__c = totalRevenue));
    }
    if(!updateEvents.isEmpty()){
        update updateEvents ;   
    }
}