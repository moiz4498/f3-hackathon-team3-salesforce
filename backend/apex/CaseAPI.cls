@RestResource(urlMapping='/api/v1/case')
global with sharing class CaseAPI {
    
    // Request structure for case creation
    global class CaseRequest {
        public String subject;
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String company;
        public String projectRequirements;
        public List<String> desiredFeatures;
        public String budget;
        public String timeline;
        public String priority;  // Optional: High, Medium, Low
    }
    
    // Response structure
    global class CaseResponse {
        public String id;
        public String status;
        public String message;
        
        public CaseResponse(String id, String status, String message) {
            this.id = id;
            this.status = status;
            this.message = message;
        }
    }
    
    @HttpPost
    global static CaseResponse createCase() {
        try {
            // Parse request body
            String requestBody = RestContext.request.requestBody.toString();
            CaseRequest req = (CaseRequest)JSON.deserialize(requestBody, CaseRequest.class);
            
            // Validate required fields
            validateRequest(req);
            
            // Create case record
            Case newCase = new Case(
                Subject = String.isNotBlank(req.subject) ? req.subject : 'Complex Requirements - Needs Human Review',
                Description = buildDescription(req),
                Origin = 'AgentDock',
                Status = 'New',
                Priority = String.isNotBlank(req.priority) ? req.priority : 'Medium',
                SuppliedEmail = req.email,
                SuppliedName = String.format('{0} {1}', new List<String>{req.firstName, req.lastName}),
                SuppliedPhone = req.phone,
                SuppliedCompany = req.company,
                Type = 'Implementation Request'
            );
            
            // Insert with security enforced
            Security.stripInaccessible(AccessType.CREATABLE, new List<Case>{newCase});
            insert newCase;
            
            // Create email notification for high priority cases
            if (req.priority == 'High') {
                sendHighPriorityNotification(newCase, req);
            }
            
            return new CaseResponse(
                newCase.Id,
                'success',
                'Case created successfully'
            );
            
        } catch(APIException e) {
            return new CaseResponse(null, 'error', e.getMessage());
        } catch(Exception e) {
            return new CaseResponse(null, 'error', 'An unexpected error occurred: ' + e.getMessage());
        }
    }
    
    private static void validateRequest(CaseRequest req) {
        List<String> errors = new List<String>();
        
        if (String.isBlank(req.email)) {
            errors.add('Email is required');
        } else if (!isValidEmail(req.email)) {
            errors.add('Invalid email format');
        }
        
        if (String.isBlank(req.company)) {
            errors.add('Company name is required');
        }
        
        if (String.isNotBlank(req.priority) && 
            !req.priority.equalsIgnoreCase('High') && 
            !req.priority.equalsIgnoreCase('Medium') && 
            !req.priority.equalsIgnoreCase('Low')) {
            errors.add('Priority must be High, Medium, or Low');
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
    
    private static String buildDescription(CaseRequest req) {
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
        
        // Add contact information section
        List<String> contactInfo = new List<String>();
        if (String.isNotBlank(req.firstName) || String.isNotBlank(req.lastName)) {
            contactInfo.add('Name: ' + String.format('{0} {1}', new List<String>{req.firstName, req.lastName}));
        }
        if (String.isNotBlank(req.email)) {
            contactInfo.add('Email: ' + req.email);
        }
        if (String.isNotBlank(req.phone)) {
            contactInfo.add('Phone: ' + req.phone);
        }
        if (String.isNotBlank(req.company)) {
            contactInfo.add('Company: ' + req.company);
        }
        
        if (!contactInfo.isEmpty()) {
            descParts.add('Contact Information:\n' + String.join(contactInfo, '\n'));
        }
        
        return String.join(descParts, '\n\n');
    }
    
    private static void sendHighPriorityNotification(Case newCase, CaseRequest req) {
        try {
            // Get the queue or user to notify (customize as needed)
            Group implementationQueue = [SELECT Id, Email FROM Group 
                                      WHERE DeveloperName = 'ImplementationTeam' 
                                      AND Type = 'Queue' LIMIT 1];
            
            if (implementationQueue != null && String.isNotBlank(implementationQueue.Email)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{implementationQueue.Email});
                mail.setSubject('High Priority Implementation Request - ' + req.company);
                
                String emailBody = 'A new high priority implementation request has been received.\n\n';
                emailBody += 'Case Number: ' + newCase.CaseNumber + '\n';
                emailBody += 'Company: ' + req.company + '\n';
                emailBody += 'Contact: ' + String.format('{0} {1}', new List<String>{req.firstName, req.lastName}) + '\n';
                emailBody += 'Email: ' + req.email + '\n\n';
                emailBody += 'Project Requirements:\n' + req.projectRequirements;
                
                mail.setPlainTextBody(emailBody);
                
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            }
        } catch(Exception e) {
            // Log error but don't fail the case creation
            System.debug(LoggingLevel.ERROR, 'Failed to send high priority notification: ' + e.getMessage());
        }
    }
    
    public class APIException extends Exception {}
} 