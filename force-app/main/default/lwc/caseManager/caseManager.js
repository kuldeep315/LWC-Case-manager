import { LightningElement, wire, track } from 'lwc';
import getCases from '@salesforce/apex/CaseManagerController.getCases';

export default class CaseManager extends LightningElement {
    // Data
    @track cases = [];
    @track totalRecords = 0;

    // Paging & sorting
    pageNumber = 1;
    pageSize = 10;
    sortBy = 'CreatedDate';
    sortDirection = 'DESC';

    // Filters
    searchKey = '';
    statusFilter = '';
    priorityFilter = '';
    startDate = null;
    endDate = null;

    // Options
    statusOptions = [
        { label: 'All', value: '' },
        { label: 'New', value: 'New' },
        { label: 'Working', value: 'Working' },
        { label: 'Closed', value: 'Closed' }
    ];
    priorityOptions = [
        { label: 'All', value: '' },
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    columns = [
        { label: 'Case Number', fieldName: 'CaseNumber', sortable: true },
        { label: 'Subject', fieldName: 'Subject', sortable: true },
        { label: 'Priority', fieldName: 'Priority', sortable: true },
        { label: 'Status', fieldName: 'Status', sortable: true },
        { label: 'Owner', fieldName: 'OwnerName', type: 'text' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date', sortable: true }
    ];

    get disablePrev() {
        return this.pageNumber === 1;
    }
    get disableNext() {
        return (this.pageNumber * this.pageSize) >= this.totalRecords;
    }

    // wire the Apex call using reactive params
    @wire(getCases, {
        searchKey: '$searchKey',
        statusFilter: '$statusFilter',
        priorityFilter: '$priorityFilter',
        ownerId: '$ownerId',
        startDate: '$startDate',
        endDate: '$endDate',
        sortBy: '$sortBy',
        sortDirection: '$sortDirection',
        pageNumber: '$pageNumber',
        pageSize: '$pageSize'
    })
    wiredCases({ error, data }) {
        if (data) {
            // Map Owner.Name to OwnerName for datatable
            this.cases = data.caseList.map(c => {
                return {
                    ...c,
                    OwnerName: c.Owner ? c.Owner.Name : ''
                };
            });
            this.totalRecords = data.totalRecords;
        } else if (error) {
            // In production show toast (omitted for brevity)
            // console.error(error);
        }
    }

    // Handlers
    handleSearch(event) {
        this.searchKey = event.target.value;
        this.pageNumber = 1;
    }

    handleStatusChange(event) {
        this.statusFilter = event.detail.value;
        this.pageNumber = 1;
    }

    handlePriorityChange(event) {
        this.priorityFilter = event.detail.value;
        this.pageNumber = 1;
    }

    handleStartDate(event) {
        this.startDate = event.target.value;
        this.pageNumber = 1;
    }

    handleEndDate(event) {
        this.endDate = event.target.value;
        this.pageNumber = 1;
    }

    handleClear() {
        this.searchKey = '';
        this.statusFilter = '';
        this.priorityFilter = '';
        this.startDate = null;
        this.endDate = null;
        this.pageNumber = 1;
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
    }

    handleNext() {
        this.pageNumber = this.pageNumber + 1;
    }

    handlePrev() {
        if (this.pageNumber > 1) {
            this.pageNumber = this.pageNumber - 1;
        }
    }
}
