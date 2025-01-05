import { LightningElement, track, wire } from 'lwc';
import getEventMetrics from '@salesforce/apex/EventDashboardController.getEventMetrics';
import createAttendee from '@salesforce/apex/AttendeeController.createAttendee';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AttendeeRegistration extends LightningElement {

    


   @track eventOptions = [];
   @track selectedEventId = '';
   @track attendeeName = '';
   @track attendeeEmail = '';
   @track selectedTicketType = '';
   @track attendeeType = ''; 
   @track selectedTicketType = ''; 


   @track attendeeTypeOptions = [
    { label: 'General', value: 'General' },
    { label: 'VIP', value: 'VIP' },
    { label: 'Speaker', value: 'Speaker' },
    { label: 'Sponsor Representative', value: 'Sponsor Representative' }
   ];
   
   @track ticketTypeOptions = [
    { label: 'General Admission', value: 'General Admission' },
    { label: 'VIP', value: 'VIP' },
    { label: 'Early Bird', value: 'Early Bird' },
    { label: 'Group Discount', value: 'Group Discount' }
   ];


   // Fetch event options
   @wire(getEventMetrics)
   wiredEvents({ error, data }) {
       if (data) {
           this.eventOptions = data.map(event => ({
               label: event.Name,
               value: event.Id
           }));
           if (this.eventOptions.length > 0) {
               this.selectedEventId = this.eventOptions[0].value;  // Set default event
           }
       } else if (error) {
           console.error(error);
       }
   }


   handleEventChange(event) {
       this.selectedEventId = event.target.value;
   }

   handleNameChange(event) {
       this.attendeeName = event.target.value;
   }

   handleEmailChange(event) {
       this.attendeeEmail = event.target.value;
   }
   handleConpanyChange(event){
    this.attendeeCompany = event.target.value ;
   }
   handleAttendeeTypeChange(event) {
       this.attendeeType = event.target.value;
   }

   handleTicketTypeChange(event) {
       this.selectedTicketType = event.target.value;
   }

   handleSubmit() {
       createAttendee({
           attendeeId: '',
           eventId: this.selectedEventId,
           attendeeName: this.attendeeName,
           attendeeEmail: this.attendeeEmail,
           attendeeCompany: this.attendeeCompany,
           attendeeType: this.attendeeType, 
           ticketType: this.selectedTicketType  
       })
       .then(() => {
           
           this.showToast('Success', 'Attendee registered successfully!', 'success');
           this.resetForm(); 
       })
       .catch(error => {
        this.showToast('Error', 'Failed to register attendee. Please try again!', 'error');
        console.error('Error:', error);
       });
   }
   showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    this.dispatchEvent(event);
}
resetForm() {
    this.attendeeName = '';
    this.attendeeEmail = '';
    this.attendeeCompany = '';
    this.attendeeType = '';
    this.selectedTicketType = '';
}
}
