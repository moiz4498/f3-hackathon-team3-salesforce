# SalesforceAgent for AgentDock

## Overview
SalesforceAgent is a specialized agent within the AgentDock MCP Server that handles Salesforce Lead Generation and Filtering. It automates the process of evaluating user requirements against AgentDock's Salesforce expertise and creates appropriate records in Salesforce.

## Features
- Lead Generation based on user requirements
- Automatic requirement validation against AgentDock's capabilities
- Salesforce integration via REST API
- Intelligent case escalation for unclear requirements
- OAuth 2.0 authentication with PKCE support
- Comprehensive logging system

## Supported Salesforce Services
- Apex Development
- Flows
- Salesforce Admin tasks
- Sales Cloud
- Service Cloud
- Commerce Cloud

## Setup

### Environment Variables
Create a `.env` file with the following variables:
```env
# Salesforce Instance Configuration
SALESFORCE_BASE_URL=your-salesforce-instance-url

# OAuth Configuration
SALESFORCE_CLIENT_ID=your-connected-app-client-id
SALESFORCE_REDIRECT_URI=http://localhost:3000/api/auth/salesforce
SALESFORCE_ACCESS_TOKEN=your-access-token  # Optional: Only if not using OAuth flow
```

### Dependencies
The agent requires the following dependencies:
```json
{
  "dependencies": {
    "axios": "^1.6.0",
    "zod": "^3.22.0"
  }
}
```

## Authentication

The agent supports two authentication methods:

1. OAuth 2.0 with PKCE (recommended)
   - Uses the modern OAuth 2.0 flow with PKCE for enhanced security
   - Requires setting up a Connected App in Salesforce
   - Handles token refresh automatically

2. Static Access Token
   - Simple setup using a pre-generated access token
   - Less secure and requires manual token updates
   - Suitable for development/testing only

### Setting up OAuth 2.0 with PKCE

1. Create a Connected App in Salesforce:
   - Go to Setup > App Manager > New Connected App
   - Enable OAuth Settings
   - Set Callback URL to match your SALESFORCE_REDIRECT_URI
   - Select required OAuth Scopes (api, refresh_token)
   - Note the Client ID for your .env file

2. Configure Environment Variables:
   - Set SALESFORCE_CLIENT_ID and SALESFORCE_REDIRECT_URI
   - Remove SALESFORCE_ACCESS_TOKEN if previously set

3. Start the authentication flow:
   - Navigate to /api/auth/salesforce
   - Follow the OAuth consent process
   - The application will handle token management

## Usage

### Input Format
The agent accepts input in the following format:
```typescript
{
  projectRequirements: string,
  contactInfo: {
    firstName?: string,
    lastName: string,
    email: string,
    phone?: string,
    company: string
  },
  desiredFeatures: string[]
}
```

### Example Usage
```typescript
const response = await salesforceNode.execute({
  input: {
    projectRequirements: "Need help with Apex development for custom triggers",
    contactInfo: {
      firstName: "John",
      lastName: "Doe",
      email: "john.doe@company.com",
      company: "Tech Corp"
    },
    desiredFeatures: ["Apex Development", "Flows"]
  }
});
```

## Logic Flow
1. Accepts user input with project requirements and contact information
2. Validates requirements against predefined expertise areas
3. If requirements match expertise:
   - Creates a Lead in Salesforce
   - Returns success response with Lead details
4. If requirements are unclear:
   - Creates a Case for manual review
   - Returns escalation response with Case details

## Error Handling
- Comprehensive error handling for API failures
- Detailed logging with timestamps and metadata
- Graceful fallback mechanisms

## Integration Points
- Salesforce REST API
  - Lead creation endpoint: `/services/data/v58.0/sobjects/Lead`
  - Case creation endpoint: `/services/data/v58.0/sobjects/Case`
  - OAuth endpoints for authentication
- AgentDock MCP Server
  - Agent registration
  - Logging system
  - Tool registry

## Logging
The agent uses a structured logging system with the following levels:
- INFO: General operation information
- WARN: Non-critical issues
- ERROR: Critical failures
- DEBUG: Development-only information

## Docker Support
The agent is fully Docker-compatible and works seamlessly within AgentDock's containerized architecture.

## Contributing
Please follow the standard pull request process and ensure all tests pass before submitting changes.
