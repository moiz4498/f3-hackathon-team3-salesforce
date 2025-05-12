import axios, { AxiosError } from 'axios';
import type { ConversationState } from './types';

// Salesforce API Configuration
const SALESFORCE_BASE_URL = 'creative-wolf-q6biwj-dev-ed.trailblaze.my.salesforce-sites.com';
const SALESFORCE_ACCESS_TOKEN = '6Cel800DdL00000BPg36888dL000000Lf1lh5p9Y4TgLnfiqCErRWjnu4CAWZPUTlaOvtKLKuSSCnzTAyxecyHrenUjTU68HfOTSW1LM8R0';

if (!SALESFORCE_ACCESS_TOKEN) {
  console.warn('SALESFORCE_ACCESS_TOKEN not set. API calls will fail.');
}

// API Headers
const getHeaders = () => ({
  Authorization: `Bearer ${SALESFORCE_ACCESS_TOKEN}`,
  'Content-Type': 'application/json'
});

export async function createLead(data: ConversationState) {
  if (!data.contactInfo) throw new Error('Contact information is required');
  if (!SALESFORCE_ACCESS_TOKEN) throw new Error('Salesforce access token not configured');
  
  const leadPayload = {
    FirstName: data.contactInfo.firstName || 'Unknown',
    LastName: data.contactInfo.lastName || 'Unknown',
    Email: data.contactInfo.email,
    Phone: data.contactInfo.phone,
    Company: data.contactInfo.company,
    Description: `
Project Requirements: ${data.projectRequirements}
Desired Features: ${data.desiredFeatures?.join(', ')}
Budget: ${data.budget}
Timeline: ${data.timeline}
Additional Notes: ${data.additionalNotes}
    `.trim(),
    LeadSource: 'AgentDock',
    Status: 'New'
  };

  try {
    console.log('Creating Salesforce Lead', { company: data.contactInfo.company });

    const response = await axios.post(
      `https://${SALESFORCE_BASE_URL}/services/apexrest/api/v1/lead`,
      leadPayload,
      { headers: getHeaders() }
    );

    console.log('Lead created successfully', { leadId: response.data.id });
    return response.data;
  } catch (error) {
    const axiosError = error as AxiosError;
    console.error('Error creating Salesforce Lead:', axiosError.response?.data || axiosError.message);
    throw new Error('Failed to create lead in Salesforce');
  }
}

export async function escalateToCase(data: ConversationState) {
  if (!data.contactInfo) throw new Error('Contact information is required');
  if (!SALESFORCE_ACCESS_TOKEN) throw new Error('Salesforce access token not configured');

  const casePayload = {
    Subject: 'Complex Requirements - Needs Human Review',
    Description: `
Project Requirements: ${data.projectRequirements}
Desired Features: ${data.desiredFeatures?.join(', ')}
Budget: ${data.budget}
Timeline: ${data.timeline}
Additional Notes: ${data.additionalNotes}

Contact Information:
Name: ${data.contactInfo.firstName || ''} ${data.contactInfo.lastName || ''}
Email: ${data.contactInfo.email}
Phone: ${data.contactInfo.phone || 'Not provided'}
Company: ${data.contactInfo.company}
    `.trim(),
    Origin: 'AgentDock',
    Status: 'New',
    Priority: 'Medium'
  };

  try {
    console.log('Escalating to Salesforce Case', { company: data.contactInfo.company });

    const response = await axios.post(
      `https://${SALESFORCE_BASE_URL}/services/apexrest/api/v1/case`,
      casePayload,
      { headers: getHeaders() }
    );

    console.log('Case created successfully', { caseId: response.data.id });
    return response.data;
  } catch (error) {
    const axiosError = error as AxiosError;
    console.error('Error creating Salesforce Case:', axiosError.response?.data || axiosError.message);
    throw new Error('Failed to create case in Salesforce');
  }
} 