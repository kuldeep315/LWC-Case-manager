@isTest
public class CaseManagerControllerTest {

    @isTest
    static void testGetCases() {
        // Create test user as owner
        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        // Insert sample cases
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            caseList.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                Priority = 'Medium',
                OwnerId = u.Id
            ));
        }
        insert caseList;

        Test.startTest();

        // Call the method with correct signature
        CaseManagerController.CaseResponse resp = CaseManagerController.getCases(
            'Test',        // searchKey
            'New',         // statusFilter
            'Medium',      // priorityFilter
            u.Id,          // ownerId
            Date.today().addDays(-10), // startDate
            Date.today(),              // endDate
            'CreatedDate', // sortBy
            'DESC',        // sortDirection
            1,             // pageNumber
            10             // pageSize
        );

        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assert(resp.caseList.size() > 0, 'Case list should not be empty');
        System.assert(resp.totalRecords > 0, 'Total records should be greater than zero');
    }


    @isTest
    static void testGetCases_NoFilters() {
        // Insert a simple case
        Case c = new Case(
            Subject = 'Sample Case',
            Status = 'Working',
            Priority = 'Low'
        );
        insert c;

        Test.startTest();

        CaseManagerController.CaseResponse resp = CaseManagerController.getCases(
            null,    // searchKey
            null,    // statusFilter
            null,    // priorityFilter
            null,    // ownerId
            null,    // startDate
            null,    // endDate
            null,    // sortBy
            null,    // sortDirection
            null,    // pageNumber
            null     // pageSize
        );

        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assert(resp.caseList.size() >= 1);
    }
}
