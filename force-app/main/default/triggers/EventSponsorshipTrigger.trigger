trigger EventSponsorshipTrigger on Event_Sponsor__c (before insert) {
	Map<Id, Decimal> eventSponsorshipMap = new Map<Id, Decimal>();
    
    Set<Id> eventIds = new Set<Id>();
    for(Event_Sponsor__c eventSponsor : Trigger.new){
        if(eventSponsor.Event__c != null){
            eventIds.add(eventSponsor.Event__c);
        }
    }
    List <Event__c> events = [Select Id, Sponsorship_Level__c, Event_Budget__c, (Select Sponsorship_Amount__c from Sponsors__r) from Event__c Where Id IN :eventIds];
   
    for(Event__c event : events){
        Decimal TotalSponsorship = 0 ; 
        for(Event_Sponsor__c eventSponsor : event.Event_Sponsors__r){
            TotalSponsorship += eventSponsor.Sponsorship_Amount__c ;
        } 
        eventSponsorshipMap.put(event.Id,TotalSponsorship);
    }
    List<Event__c> updateEvents = new List<Event__c>() ;
    for(Event__c event : events){
        Decimal Budget = event.Event_Budget__c != 0 ? event.Event_Budget__c : 0 ;
        if(eventSponsorshipMap.get(event.Id) >= Budget){
            event.Sponsorship_Level__c = 'Fully Sponsored' ;
        }else if(eventSponsorshipMap.get(event.Id)  < Budget){
            event.Sponsorship_Level__c = 'Partially Sponsored' ;
        }else {
            event.Sponsorship_Level__c = 'Not Sponsored';
        }
        updateEvents.add(event); 
    }
    update updateEvents ;
}