trigger EventStatusTrigger on Event__c (after update) {
	List<Session__c> sessionsToCreate = new List<Session__c>();
    
    for(Event__c eventRecord : Trigger.new){
        Event__c oldEvent = Trigger.oldMap.get(eventRecord.Id);
        if(eventRecord.Status__c == 'Open for Registration' && oldEvent.Status__c != 'Open for Registration'){
            String[] sessionNames = new String[] {
                'session1', 'session2', 'session3', 'session4', 'session5'};
                    DateTime startDateTime =  eventRecord.Event_Start_Date__c ;
            
            for(Integer i = 0 ; i < sessionNames.size() ; i++){
               Session__c newSession = new Session__c();
                newSession.Event__c = eventRecord.Id ;
                 newSession.Name =  sessionNames[i] ;
                newSession.Session_Start_Time__c = startDateTime.addHours(i) ;
                newSession.Session_End_Time__c = newSession.Session_Start_Time__c.addHours(2); 
                
                sessionsToCreate.add(newSession);
                
            }
                }
             }
    if(!sessionsToCreate.isEmpty()){ 
        insert sessionsToCreate ;
    }
        }