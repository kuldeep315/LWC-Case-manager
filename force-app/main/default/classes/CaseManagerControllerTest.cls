@IsTest
private class CaseManagerControllerTest {
    @IsTest static void testGetCases_basic() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 25; i++) {
            cases.add(new Case(Subject = 'Test case ' + i,
                               Status = (i % 2 == 0) ? 'New' : 'Working',
                               Priority = (i % 3 == 0) ? 'High' : 'Medium',
                               Description = 'desc ' + i));
        }
        insert cases;

        Test.startTest();
            CaseManagerController.CaseResponse res = CaseManagerController.getCases(
                'Test', // searchKey
                null, // statusFilter
                null, // priorityFilter
                null, // ownerId
                null, // startDate
                null, // endDate
                'CreatedDate', // sortBy
                'DESC', // sortDirection
                1, // pageNumber
                10 // pageSize
            );
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assert(res.caseList.size() <= 10);
        System.assert(res.totalRecords >= 25);
    }
}
