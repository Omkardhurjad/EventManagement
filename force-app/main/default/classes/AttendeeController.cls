public with sharing class AttendeeController {
  /*  @AuraEnabled
    public static string RegisterAndPay(Map<String, String> attendeeMap){
     

      String paymentResponse = callPaymentGateway(ticket);
      if( paymentResponse == 'Success'){
          //update payment status
          ticket.Payment_Status__c = 'Paid';
      }else{
        ticket.Payment_Status__c = 'Failed';
      }
       update ticket;
      return paymentResponse == 'Success' ? 'Payment Successful' : 'Payment Failed';
    }
    @TestVisible
    private static String callPaymentGateway(Ticket__c ticket){
      HttpRequest req = new HttpRequest();
      req.setEndpoint('https://mockpaymentgateway.com/verify');
      req.setMethod('POST');
      req.setBody('ticketId='+ticket.id+'&amount=100');
      HttpResponse res = new HttpResponse();
  
      if(res.getStatusCode() == 200){
        return 'Success';
      }else{
        return 'Failed';
      }
    }*/ 
    
    @AuraEnabled
    public static void createAttendee(String attendeeId, Id eventId, String attendeeName, String attendeeEmail, String attendeeCompany,String attendeeType, String ticketType) {
        Attendee__c attendee;
        
        if (String.isNotBlank(attendeeId)) {
            attendee = [SELECT Id, Name, Email__c,ComPany__c, Attendee_Type__c, Event__c FROM Attendee__c WHERE Id = :attendeeId LIMIT 1];
        } else {

            attendee = new Attendee__c();
        }
        
        attendee.Name = attendeeName;
        attendee.Email__c = attendeeEmail;
        attendee.ComPany__c = attendeeCompany;
        attendee.Attendee_Type__c = attendeeType; 
        attendee.Event__c = eventId;

        
        upsert attendee;
        
        
        Ticket__c ticket = [SELECT Id, Ticket_Type__c, Payment_Status__c, Attendee__c, Event__c FROM Ticket__c WHERE Attendee__c = :attendee.Id AND Event__c = :eventId LIMIT 1];
        
        if (ticket == null) {
            ticket = new Ticket__c();
        }
        
       
        ticket.Ticket_Type__c = ticketType;
        ticket.Payment_Status__c = 'Pending'; 
        ticket.Attendee__c = attendee.Id;
        ticket.Event__c = eventId;
        
        
        upsert ticket;
    }

}
  