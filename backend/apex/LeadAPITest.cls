@IsTest
private class LeadAPITest {
    
    @TestSetup
    static void setup() {
        // No setup needed for now
    }
    
    @IsTest
    static void testCreateLead_Success() {
        // Arrange
        LeadAPI.LeadRequest req = new LeadAPI.LeadRequest();
        req.firstName = 'John';
        req.lastName = 'Doe';
        req.email = 'john.doe@test.com';
        req.phone = '1234567890';
        req.company = 'Test Corp';
        req.projectRequirements = 'Need Salesforce implementation';
        req.desiredFeatures = new List<String>{'Sales Cloud', 'Service Cloud'};
        req.budget = '$50,000';
        req.timeline = '3 months';
        req.additionalNotes = 'Urgent requirement';
        
        // Set up the REST context
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/lead';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        LeadAPI.LeadResponse response = LeadAPI.createLead();
        Test.stopTest();
        
        // Assert
        System.assertEquals('success', response.status, 'Lead creation should succeed');
        System.assertNotEquals(null, response.id, 'Lead ID should not be null');
        
        // Verify lead was created correctly
        Lead createdLead = [SELECT Id, FirstName, LastName, Email, Company, Description FROM Lead WHERE Id = :response.id];
        System.assertEquals(req.firstName, createdLead.FirstName);
        System.assertEquals(req.lastName, createdLead.LastName);
        System.assertEquals(req.email, createdLead.Email);
        System.assertEquals(req.company, createdLead.Company);
        System.assert(createdLead.Description.contains(req.projectRequirements));
    }
    
    @IsTest
    static void testCreateLead_MissingRequiredFields() {
        // Arrange
        LeadAPI.LeadRequest req = new LeadAPI.LeadRequest();
        req.firstName = 'John';
        // Missing email and company
        
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/lead';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        LeadAPI.LeadResponse response = LeadAPI.createLead();
        Test.stopTest();
        
        // Assert
        System.assertEquals('error', response.status);
        System.assert(response.message.contains('Email is required'));
        System.assert(response.message.contains('Company name is required'));
    }
    
    @IsTest
    static void testCreateLead_InvalidEmail() {
        // Arrange
        LeadAPI.LeadRequest req = new LeadAPI.LeadRequest();
        req.firstName = 'John';
        req.lastName = 'Doe';
        req.email = 'invalid.email'; // Invalid email format
        req.company = 'Test Corp';
        
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/lead';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        LeadAPI.LeadResponse response = LeadAPI.createLead();
        Test.stopTest();
        
        // Assert
        System.assertEquals('error', response.status);
        System.assert(response.message.contains('Invalid email format'));
    }
    
    @IsTest
    static void testCreateLead_InvalidJSON() {
        // Arrange
        RestRequest request = new RestRequest();
        request.requestUri = '/api/v1/lead';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('invalid json');
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        LeadAPI.LeadResponse response = LeadAPI.createLead();
        Test.stopTest();
        
        // Assert
        System.assertEquals('error', response.status);
        System.assert(response.message.contains('unexpected error'));
    }
} 