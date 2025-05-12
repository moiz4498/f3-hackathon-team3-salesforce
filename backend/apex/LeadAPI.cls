@RestResource(urlMapping='/api/v1/lead')
global with sharing class LeadAPI {
    
    // Request structure for lead creation
    global class LeadRequest {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String company;
        public String projectRequirements;
        public List<String> desiredFeatures;
        public String budget;
        public String timeline;
        public String additionalNotes;
    }
    
    // Response structure
    global class LeadResponse {
        public String id;
        public String status;
        public String message;
        
        public LeadResponse(String id, String status, String message) {
            this.id = id;
            this.status = status;
            this.message = message;
        }
    }
    
    @HttpPost
    global static LeadResponse createLead() {
        try {
            // Parse request body
            String requestBody = RestContext.request.requestBody.toString();
            LeadRequest req = (LeadRequest)JSON.deserialize(requestBody, LeadRequest.class);
            
            // Validate required fields
            validateRequest(req);
            
            // Create lead record
            Lead newLead = new Lead(
                FirstName = req.firstName,
                LastName = String.isNotBlank(req.lastName) ? req.lastName : 'Unknown',
                Email = req.email,
                Phone = req.phone,
                Company = req.company,
                Description = buildDescription(req),
                LeadSource = 'AgentDock',
                Status = 'New'
            );
            
            // Insert with security enforced
            Security.stripInaccessible(AccessType.CREATABLE, new List<Lead>{newLead});
            insert newLead;
            
            return new LeadResponse(
                newLead.Id,
                'success',
                'Lead created successfully'
            );
            
        } catch(APIException e) {
            return new LeadResponse(null, 'error', e.getMessage());
        } catch(Exception e) {
            return new LeadResponse(null, 'error', 'An unexpected error occurred: ' + e.getMessage());
        }
    }
    
    private static void validateRequest(LeadRequest req) {
        List<String> errors = new List<String>();
        
        if (String.isBlank(req.email)) {
            errors.add('Email is required');
        } else if (!isValidEmail(req.email)) {
            errors.add('Invalid email format');
        }
        
        if (String.isBlank(req.company)) {
            errors.add('Company name is required');
        }
        
        if (!errors.isEmpty()) {
            throw new APIException(String.join(errors, ', '));
        }
    }
    
    private static Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher matcher = emailPattern.matcher(email);
        return matcher.matches();
    }
    
    private static String buildDescription(LeadRequest req) {
        List<String> descParts = new List<String>();
        
        if (String.isNotBlank(req.projectRequirements)) {
            descParts.add('Project Requirements:\n' + req.projectRequirements);
        }
        
        if (req.desiredFeatures != null && !req.desiredFeatures.isEmpty()) {
            descParts.add('Desired Features:\n' + String.join(req.desiredFeatures, ', '));
        }
        
        if (String.isNotBlank(req.budget)) {
            descParts.add('Budget:\n' + req.budget);
        }
        
        if (String.isNotBlank(req.timeline)) {
            descParts.add('Timeline:\n' + req.timeline);
        }
        
        if (String.isNotBlank(req.additionalNotes)) {
            descParts.add('Additional Notes:\n' + req.additionalNotes);
        }
        
        return String.join(descParts, '\n\n');
    }
    
    public class APIException extends Exception {}
} 