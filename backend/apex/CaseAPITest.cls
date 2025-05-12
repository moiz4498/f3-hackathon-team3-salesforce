@IsTest
private class CaseAPITest {
    
    @TestSetup
    static void setup() {
        // Create a test queue for high priority notifications
        Group testQueue = new Group(
            Name = 'Implementation Team',
            DeveloperName = 'ImplementationTeam',
            Type = 'Queue',
            Email = 'implementation@test.com'
        );
        insert testQueue;
        
        // Create queue members if needed
        // This part might need customization based on your org's setup
        /*
        List<GroupMember> members = new List<GroupMember>();
        for(User u : [SELECT Id FROM User WHERE IsActive = true LIMIT 1]) {
            members.add(new GroupMember(GroupId = testQueue.Id, UserOrGroupId = u.Id));
        }
        insert members;
        */
    }
    
    @IsTest
    static void testCreateCase_Success() {
        // Arrange
        CaseAPI.CaseRequest req = new CaseAPI.CaseRequest();
        req.subject = 'Test Implementation';
        req.firstName = 'Jane';
        req.lastName = 'Smith';
        req.email = 'jane.smith@test.com';
        req.phone = '1234567890';
        req.company = 'Tech Corp';
        req.projectRequirements = 'Complex Salesforce customization';
        req.desiredFeatures = new List<String>{'Custom Development', 'Integration'};
        req.budget = '$100,000';
        req.timeline = '6 months';
        req.priority = 'Medium';
        
        // Set up the REST context
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/case';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Assert
        System.assertEquals('success', response.status, 'Case creation should succeed');
        System.assertNotEquals(null, response.id, 'Case ID should not be null');
        
        // Verify case was created correctly
        Case createdCase = [SELECT Id, Subject, SuppliedEmail, SuppliedCompany, Priority, Description 
                          FROM Case WHERE Id = :response.id];
        System.assertEquals(req.subject, createdCase.Subject);
        System.assertEquals(req.email, createdCase.SuppliedEmail);
        System.assertEquals(req.company, createdCase.SuppliedCompany);
        System.assertEquals('Medium', createdCase.Priority);
        System.assert(createdCase.Description.contains(req.projectRequirements));
    }
    
    @IsTest
    static void testCreateCase_HighPriority() {
        // Arrange
        CaseAPI.CaseRequest req = new CaseAPI.CaseRequest();
        req.subject = 'Urgent Implementation';
        req.firstName = 'Jane';
        req.lastName = 'Smith';
        req.email = 'jane.smith@test.com';
        req.phone = '1234567890';
        req.company = 'Tech Corp';
        req.projectRequirements = 'Urgent Salesforce customization';
        req.priority = 'High';
        
        // Set up the REST context
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/case';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        
        // Verify email notification
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        // Assert
        System.assertEquals('success', response.status, 'High priority case creation should succeed');
        System.assertNotEquals(null, response.id, 'Case ID should not be null');
        
        // Verify case was created with high priority
        Case createdCase = [SELECT Id, Priority FROM Case WHERE Id = :response.id];
        System.assertEquals('High', createdCase.Priority);
        
        // Verify email was sent (if email deliverability is enabled)
        System.assert(emailInvocations > 0, 'High priority notification email should be sent');
    }
    
    @IsTest
    static void testCreateCase_MissingRequiredFields() {
        // Arrange
        CaseAPI.CaseRequest req = new CaseAPI.CaseRequest();
        req.firstName = 'Jane';
        // Missing email and company
        
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/case';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Assert
        System.assertEquals('error', response.status);
        System.assert(response.message.contains('Email is required'));
        System.assert(response.message.contains('Company name is required'));
    }
    
    @IsTest
    static void testCreateCase_InvalidPriority() {
        // Arrange
        CaseAPI.CaseRequest req = new CaseAPI.CaseRequest();
        req.email = 'test@test.com';
        req.company = 'Test Corp';
        req.priority = 'Invalid'; // Invalid priority value
        
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/case';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Assert
        System.assertEquals('error', response.status);
        System.assert(response.message.contains('Priority must be High, Medium, or Low'));
    }
    
    @IsTest
    static void testCreateCase_InvalidJSON() {
        // Arrange
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/case';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('invalid json');
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        CaseAPI.CaseResponse response = CaseAPI.createCase();
        Test.stopTest();
        
        // Assert
        System.assertEquals('error', response.status);
        System.assert(response.message.contains('unexpected error'));
    }
} 