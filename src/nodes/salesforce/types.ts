// Define conversation states
export type ConversationState = {
  stage: 'initial' | 'gathering_requirements' | 'contact_info' | 'qualification' | 'complete';
  projectRequirements?: string;
  contactInfo?: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phone?: string;
    company?: string;
  };
  desiredFeatures?: string[];
  budget?: string;
  timeline?: string;
  additionalNotes?: string;
  context?: string; // Store conversation context
}; 