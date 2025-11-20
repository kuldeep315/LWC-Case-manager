/**
 * CaseManagerController
 * Provides server-side querying for Cases with filtering, sorting and pagination.
 *
 * Key features:
 * - Parameterized dynamic SOQL with input escaping to avoid SOQL injection.
 * - Server-side pagination (LIMIT + OFFSET).
 * - Returns results + total count in a wrapper.
 *
 * Note: For large-scale datasets consider using Batch/Aggregate queries or continuations.
 */
public with sharing class CaseManagerController {

    public class CaseResponse {
        @AuraEnabled public List<Case> caseList { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        public CaseResponse(List<Case> cases, Integer totalCount) {
            this.caseList = cases;
            this.totalRecords = totalCount;
        }
    }

    @AuraEnabled(cacheable=true)
    public static CaseResponse getCases(
        String searchKey,
        String statusFilter,
        String priorityFilter,
        Id ownerId,
        Date startDate,
        Date endDate,
        String sortBy,
        String sortDirection,
        Integer pageNumber,
        Integer pageSize
    ) {
        // Validate paging params
        if (pageNumber == null || pageNumber < 1) pageNumber = 1;
        if (pageSize == null || pageSize < 1) pageSize = 10;
        if (String.isBlank(sortBy)) sortBy = 'CreatedDate';
        if (String.isBlank(sortDirection)) sortDirection = 'DESC';

        // Build WHERE clauses safely using escaped inputs
        List<String> whereParts = new List<String>();

        if (!String.isBlank(searchKey)) {
            String escaped = '%' + String.escapeSingleQuotes(searchKey) + '%';
            whereParts.add('(Subject LIKE \'' + escaped + '\' OR Description LIKE \'' + escaped + '\')');
        }
        if (!String.isBlank(statusFilter)) {
            whereParts.add('Status = \'' + String.escapeSingleQuotes(statusFilter) + '\'');
        }
        if (!String.isBlank(priorityFilter)) {
            whereParts.add('Priority = \'' + String.escapeSingleQuotes(priorityFilter) + '\'');
        }
        if (ownerId != null) {
            whereParts.add('OwnerId = \'' + String.escapeSingleQuotes(String.valueOf(ownerId)) + '\'');
        }
        if (startDate != null && endDate != null) {
            // Use date literals via ISO format
            String s = startDate.format();
            String e = endDate.addDays(1).format(); // inclusive endDate by adding 1 day and using < end
            whereParts.add('CreatedDate >= ' + s + 'T00:00:00Z' /* placeholder - will use bind instead below */);
            // But easier/safer: use WHERE CreatedDate >= :startDate AND CreatedDate < :endDatePlusOne in dynamic built query is not possible, so fallback to using static query with binds by building QueryLocator? 
            // To keep method cacheable we will construct a dynamic query using Date.iso8601 formats:
            whereParts.remove(whereParts.size()-1);
            whereParts.add('CreatedDate >= ' + DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
            whereParts.add('CreatedDate < ' + DateTime.newInstance(endDate.addDays(1).year(), endDate.addDays(1).month(), endDate.addDays(1).day()).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        }

        String base = 'SELECT Id, CaseNumber, Subject, Status, Priority, OwnerId, Owner.Name, CreatedDate FROM Case';
        if (!whereParts.isEmpty()) {
            base += ' WHERE ' + String.join(whereParts, ' AND ');
        }

        // Validate sortBy column to prevent injection via column name
        Set<String> allowedSorts = new Set<String>{'CreatedDate','CaseNumber','Subject','Status','Priority','Owner.Name'};
        String sortExpr = 'CreatedDate';
        if (allowedSorts.contains(sortBy)) {
            sortExpr = sortBy;
        }
        String dir = (sortDirection != null && sortDirection.toUpperCase() == 'ASC') ? 'ASC' : 'DESC';
        base += ' ORDER BY ' + sortExpr + ' ' + dir;

        Integer offsetVal = (pageNumber - 1) * pageSize;
        // Append LIMIT & OFFSET with safe integer interpolation
        base += ' LIMIT ' + String.valueOf(pageSize) + ' OFFSET ' + String.valueOf(offsetVal);

        List<Case> caseList = Database.query(base);

        // totalRecords: use aggregate query with same filters (without LIMIT/OFFSET)
        String countQuery = 'SELECT COUNT() FROM Case';
        if (!whereParts.isEmpty()) {
            countQuery += ' WHERE ' + String.join(whereParts, ' AND ');
        }
        Integer total = (Integer)Database.countQuery(countQuery);

        return new CaseResponse(caseList, total);
    }
}

