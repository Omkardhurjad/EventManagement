public with sharing class EventDashboardController {

    @AuraEnabled(cacheable=true) // Important: Make this cacheable
    public static String getUserProfile() {
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        return currentUser.Profile.Name;
    }
 
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getEventMetrics() {
        // Query events along with ticket details, including status
        List<Event__c> events = [
            SELECT Id, Name, Event_Start_Date__c, Max_Attendee_Capacity__c, Event_Revenue__c,
                   (SELECT Id, Payment_Status__c FROM Tickets__r)
            FROM Event__c
            WHERE Event_Start_Date__c >= TODAY
            ORDER BY Event_Start_Date__c ASC
        ];
    
        List<Map<String, Object>> eventMetrics = new List<Map<String, Object>>();
        for (Event__c event : events) {
            Integer ticketSold = 0;
            Integer ticketsRefunded = 0;
            if (event.Tickets__r != null) {
                for (Ticket__c ticket : event.Tickets__r) {
                    if (ticket.Payment_Status__c == 'Refunded') {
                        ticketsRefunded++;
                    } else {
                        ticketSold++;
                    }
                }
            }
    
            Integer ticketRemaining = (Integer)event.Max_Attendee_Capacity__c - ticketSold + ticketsRefunded;
    
            eventMetrics.add(new Map<String, Object>{
                'Id' => event.Id,
                'Name' => event.Name,
                'Event_Start_Date__c' => event.Event_Start_Date__c,
                'Max_Attendee_Capacity__c' => event.Max_Attendee_Capacity__c,
                'Ticket_Sold' => ticketSold,
                'Tickets_Refunded' => ticketsRefunded,
                'Ticket_Remaining' => ticketRemaining
                //'Event_Revenue__c' => event.Event_Revenue__c
            });
        }
        return eventMetrics;
    }
    
    
        @AuraEnabled
        public static void updateEvents(List<Map<String, Object>> data) {
            List<Event__c> EventsToUpdate = new List<Event__c>();
    
            for (Map<String, Object> record : data) {
                Event__c event = new Event__c();
                event.Id = (String)record.get('Id');
                if (record.containsKey('Event_Start_Date__c')) {
                    event.Event_Start_Date__c = Date.valueOf((String)record.get('Event_Start_Date__c'));
                }
                if (record.containsKey('Max_Attendee_Capacity__c')) {
                    event.Max_Attendee_Capacity__c = Integer.valueOf((String)record.get('Max_Attendee_Capacity__c'));
                }
                EventsToUpdate.add(event);
            }
    
            try {
                update EventsToUpdate;
            } catch (Exception e) {
                throw new AuraHandledException('Failed to update events: ' + e.getMessage());
            }
        }
        
        @AuraEnabled(cacheable=true)  
public static List<Event_Sponsor__c> getSponsorsByEvent(Id eventId) {
    return [
        SELECT Sponsor__r.Id, Sponsor__r.Name ,Sponsor__r.Logo_URL__c
        FROM Event_Sponsor__c 
        WHERE Event__c = :eventId
    ];
}

        @AuraEnabled(cacheable=true)
        public static List<Session__c> getSessionsByEvent(Id eventId) {
            return [SELECT Id, Name, Session_Start_Time__c,Session_End_Time__c, Track_Topic__c, Speaker_Name__c FROM Session__c WHERE Event__c = :eventId];
        }

    }
    