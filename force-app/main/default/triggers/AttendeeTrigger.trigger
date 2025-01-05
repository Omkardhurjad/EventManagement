trigger AttendeeTrigger on Attendee__c (after insert) {
    List<Ticket__c> ticketsToInsert = new List<Ticket__c>();
    Map<Id, Ticket__c> ticketMap = new Map<Id, Ticket__c>();
    
    // Create Ticket__c records for each new Attendee__c
    for (Attendee__c attendee : Trigger.new) {
        if (attendee.Event__c != null) {
            Ticket__c ticket = new Ticket__c();
            ticket.Event__c = attendee.Event__c;
            ticket.Attendee__c = attendee.Id;
            ticket.Payment_Status__c = 'Pending';
            ticket.Ticket_Type__c = 'General Admission';
            ticketsToInsert.add(ticket);
        }
    }
    
    // Insert tickets into the database
    if (!ticketsToInsert.isEmpty()) {
        insert ticketsToInsert;
    }
    
    // Map tickets by ID for payment processing
    for (Ticket__c ticket : ticketsToInsert) {
        ticketMap.put(ticket.Id, ticket);
    }
    
    // Enqueue payment processing if there are tickets
    if (!ticketMap.isEmpty()) {
         PaymentGateway.simulatePayments(new List<Id>(ticketMap.keySet()));
    }
}