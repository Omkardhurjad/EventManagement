trigger TicketCapacityTrigger on Ticket__c (before insert) {
	Map<Id, Event__c> eventCapacityMap = new Map<Id, Event__c>();
    Set<Id> eventIds = new Set<Id>();
    
    for(Ticket__c ticket : Trigger.new){
        if(ticket.Event__c != null){
            eventIds.add(ticket.Event__c);
        }
    }
    
    if(!eventIds.isEmpty()){
        eventCapacityMap = new Map<Id, Event__c>([Select Id, Name, Max_Attendee_Capacity__c,(Select Id from Tickets__r) from Event__c WHERE Id IN :eventIds]);
        
        for(Ticket__c ticket : Trigger.new){
    Event__c relatedEvent = eventCapacityMap.get(ticket.Event__c);
        Integer currentTickets = relatedEvent.Tickets__r.size();
        Integer capacity = relatedEvent.Max_Attendee_Capacity__c != null  ? relatedEvent.Max_Attendee_Capacity__c.intValue() : 0 ;      
            
            if(currentTickets >= capacity){
                ticket.addError('Event Capacity reached');
            }
         }
    
    }
}