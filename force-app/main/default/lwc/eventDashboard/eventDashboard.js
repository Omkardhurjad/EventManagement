import { LightningElement, track, wire, api} from 'lwc';
import getEventMetrics from '@salesforce/apex/EventDashboardController.getEventMetrics';
import updateEvents from '@salesforce/apex/EventDashboardController.updateEvents';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import getSponsorsByEvent from '@salesforce/apex/EventDashboardController.getSponsorsByEvent';
import getUserProfile from '@salesforce/apex/EventDashboardController.getUserProfile';
import getSessionsByEvent from '@salesforce/apex/EventDashboardController.getSessionsByEvent';


export default class EventDashboard extends NavigationMixin(LightningElement) {
    
    @track events = [];
    @track filteredEvents = [];
    @track searchKey = '';
    @track isSponsorModalOpen = false ;
    @track isSessionsModalOpen = false ;
    @track sessions = [];
    @track sponsors = [];
    @track columns = [
        { label: 'Event Name', fieldName: 'Name', type: 'text', sortable: true, editable: false },
        { label: 'Event Date', fieldName: 'Event_Start_Date__c', type: 'date', editable: false },
        { label: 'Max Capacity', fieldName: 'Max_Attendee_Capacity__c', type: 'number', editable: false },
        { label: 'Tickets Sold', fieldName: 'Ticket_Sold', type: 'number' },
        { label: 'Remaining Tickets', fieldName: 'Ticket_Remaining', type: 'number' },
       // { label: 'Event Revenue', fieldName: 'Event_Revenue__c', type: 'currency' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [],
                menuAlignment: 'right'
            }
        }
    ];
    draftValues = [];
    connectedCallback() { // Call fetchUserProfile in connectedCallback
        this.fetchUserProfile();
    }
    wiredResult;

    @wire(getEventMetrics)
    wiredEvents(result) {
        this.wiredResult = result;
        if (result.data) {
            this.events = result.data;
            this.filteredEvents = this.events;
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }
    fetchUserProfile() {
        getUserProfile()
            .then(profile => {
                const updatedColumns = [...this.columns];
                updatedColumns.find(col => col.type === 'action').typeAttributes.rowActions = this.getRowActions(profile);
                this.columns = updatedColumns;
            })
            .catch(error => {
                console.error('Error getting user profile:', error);
                const updatedColumns = [...this.columns];
                updatedColumns.find(col => col.type === 'action').typeAttributes.rowActions = this.getRowActions();
                this.columns = updatedColumns;
            });
    }
    
    getRowActions(profile = null) {
        const defaultActions = [
            { label: 'View Sessions', name: 'view_sessions' },
            { label: 'View Sponsors', name: 'view_sponsors' }
        ];
    
        if (profile) {
            const adminStaffActions = [
                { label: 'Mark Event Open', name: 'mark_open' },
                { label: 'View Sessions', name: 'view_sessions' },
                { label: 'View Sponsors', name: 'view_sponsors' }
            ];
    
            if (['System Administrator', 'Event Manager Profile', 'Event Staff Profile'].includes(profile)) {
                return adminStaffActions;
            } else if (profile === 'Attendee Profile') {
                return defaultActions;
            }
        }
        return [];
    }
    

    handleSave(event) {
        const updatedEvents = event.detail.draftValues;

        updatedEvents.forEach(record => {
            if (record.Event_Start_Date__c) {
                record.Event_Start_Date__c = new Date(record.Event_Start_Date__c).toISOString().split('T')[0];
            }
        });

        updateEvents({ data: updatedEvents })
            .then(() => {
                this.showToast('Success', 'Events Updated', 'success');
                this.draftValues = [];
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'mark_open':
                this.markEventOpen(row.Id);
                break;
            case 'view_sessions':
                this.viewSessions(row.Id);
                break;
            case 'view_sponsors':
                this.viewSponsors(row.Id);
                break;
        }
    }

    markEventOpen(eventId) {
        this.recordId = eventId;
  if (this.wiredEvents && this.wiredEvents.data) {
    const event = this.wiredEvents.data.find(event => event.Id === eventId);
    if (event && event.Status__c === 'Open for Registration') {
      //this.showToast('Info', 'Event is already Open for Registration.', 'info');
      return; 
    }
  }
        const record = {
            Id: eventId,
            Status__c: 'Open for Registration'
        };
    

        return updateRecord({ fields: record })
            .then(() => {
                this.showToast('Success', 'Event marked as Open for Registration.', 'success');
                
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                console.error('Error updating event status:', error);
                this.showToast('Error', 'Failed to mark event as Open. ' + error.body.message, 'error');
            });
    }
    

    viewSessions(eventId) {
       this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: eventId,
                objectApiName: 'Event__c', 
                //relationshipApiName: 'Sessions__r', 
                actionName: 'view'
            }
        });
        getSessionsByEvent({ eventId })
            .then((data) => {
                console.log('Fetched Sessions:', data);
                this.sessions = data;
                this.isSessionsModalOpen = true;
                console.log('isSessionsModalOpen value is',this.isSessionsModalOpen)
            })
            .catch((error) => {
                console.error('Error fetching sessions:', error);
                this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
            });
    }

    closeSessionsModal(){
        this.isSessionsModalOpen = false ;
        this.sessions = [];
    }
    

    viewSponsors(eventId) {
        this.error = null; // Clear any previous errors
        getSponsorsByEvent({ eventId })
            .then((data) => {
                if (data && data.length > 0) {
                    this.sponsors = data.map(record => record.Sponsor__r);
                } else {
                    this.sponsors = []; // Handle case where no sponsors are found
                    this.showToast('Info', 'No sponsors found for this event.', 'info');
                }
                this.isSponsorModalOpen = true;
            })
            .catch((error) => {
                console.error('Error fetching sponsors:', error);
                this.error = error; // Store the error
                this.showToast('Error', error.body?.message || 'Unknown error', 'error');
            });
    }

    closeSponsorModal() {
        this.isSponsorModalOpen = false;
        this.sponsors = [];
        this.error = null; // Clear the error when closing the modal
    }


    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();

        this.filteredEvents = this.events.filter(event => {
            const nameMatches = event.Name.toLowerCase().includes(this.searchKey);
            const dateMatches = event.Event_Start_Date__c.includes(this.searchKey);
            return nameMatches || dateMatches;
        });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(toastEvent);
    }
}
