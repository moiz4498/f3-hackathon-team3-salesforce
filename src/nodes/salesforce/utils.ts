import type { ConversationState } from './types';

// Valid requirements and expertise areas
export const VALID_REQUIREMENTS = [
  'Apex Development',
  'Flows',
  'Salesforce Admin tasks',
  'Sales Cloud',
  'Service Cloud',
  'Commerce Cloud'
];

// Helper function to extract information from LLM response
export async function extractInformation(text: string, state: ConversationState, llmContext: any) {
  const prompt = `
Extract relevant information from the following user message for a Salesforce lead qualification conversation.
Current conversation stage: ${state.stage}

User message: "${text}"

Extract and format the information as JSON with these possible fields (only include fields that are clearly present):
- projectRequirements (if message contains project details)
- desiredFeatures (array of Salesforce features mentioned)
- budget (if budget is mentioned)
- timeline (if timeline is mentioned)
- contactInfo (object with firstName, lastName, email, phone, company if any contact info is present)
- additionalNotes (any other relevant information)

Only extract information that is explicitly mentioned. Don't make assumptions.
`;

  try {
    const response = await llmContext.llm.complete({
      prompt,
      temperature: 0.1, // Low temperature for more precise extraction
      max_tokens: 500
    });

    const extractedInfo = JSON.parse(response.content);
    return extractedInfo;
  } catch (error) {
    console.error('Error extracting information:', error);
    return {};
  }
}

// Function to generate contextual response using LLM
export async function generateResponse(state: ConversationState, llmContext: any, additionalContext: string = '') {
  const prompt = `
You are a professional sales representative for our company, a leading Salesforce solution provider. Your goal is to quickly qualify leads and facilitate connection with our expert team.

Key Guidelines:
- Keep the conversation high-level and focused
- Don't dive into technical details
- If the client wants detailed discussion or seems to have complex needs, offer to connect them with our expert team
- Gather only essential information needed for basic qualification

Current conversation stage: ${state.stage}

${state.stage === 'initial' ? `
You should:
- Warmly welcome the potential client
- Ask for a brief overview of what they're looking to achieve with Salesforce
- Keep it simple and high-level
- If they mention complex requirements or want detailed discussion, offer to connect them with our expert team
` : ''}

${state.stage === 'gathering_requirements' ? `
You should:
- Acknowledge their overview
- Ask for rough timeline expectations
- Get a general budget range (if not mentioned)
- If they start getting into technical details, politely steer them towards a call with our expert team
` : ''}

${state.stage === 'contact_info' ? `
You should:
- Thank them for the overview
- Explain that we'd like to have our expert team reach out
- Request basic contact details:
  * Name and company
  * Email address
  * Phone number (optional)
` : ''}

${state.stage === 'qualification' ? `
You should:
- Thank them for their interest
- Confirm that our team will reach out soon
- Set expectation for next steps
` : ''}

Conversation context:
${state.context || 'Initial conversation'}

Current information collected:
${JSON.stringify(state, null, 2)}

Additional context: ${additionalContext}

Remember:
1. Keep it high-level - avoid detailed technical discussions
2. If they want specifics, offer to connect them with our expert team
3. Focus on basic qualification (overview, timeline, budget)
4. Quick handoff is better than lengthy discussion
5. Create a case if: they request human contact, mention complex needs, or seem uncertain

Response should be brief, professional, and focused on moving to expert team contact when appropriate.
`;

  try {
    const response = await llmContext.llm.complete({
      prompt,
      temperature: 0.7,
      max_tokens: 300
    });

    return response.content;
  } catch (error) {
    console.error('Error generating response:', error);
    return generateFallbackResponse(state);
  }
}

// Fallback response generator if LLM fails
export function generateFallbackResponse(state: ConversationState): string {
  switch (state.stage) {
    case 'initial':
      return "Hello! I'd love to understand what you're looking to achieve with Salesforce. Could you give me a brief overview?";
    case 'gathering_requirements':
      return "Thanks for sharing. Could you give me an idea of your timeline and budget expectations?";
    case 'contact_info':
      return "Great! To have our expert team reach out with more information, could you share your contact details?";
    case 'qualification':
      return "Thank you for your interest. We'll have our expert team reach out to discuss your needs in detail.";
    default:
      return "How else can I help connect you with our Salesforce implementation team?";
  }
}

// Function to analyze requirements complexity
export function analyzeRequirements(state: ConversationState): {
  isComplex: boolean;
  missingInfo: string[];
  matchedFeatures: string[];
} {
  const missingInfo = [];
  // Only check for essential information
  if (!state.projectRequirements) missingInfo.push('basic requirements');
  if (!state.contactInfo?.email) missingInfo.push('contact email');
  if (!state.contactInfo?.company) missingInfo.push('company name');

  const matchedFeatures = state.desiredFeatures?.filter(
    feature => VALID_REQUIREMENTS.includes(feature)
  ) || [];

  // Simplified complexity check
  const isComplex = Boolean(
    state.projectRequirements?.toLowerCase().includes('complex') ||
    state.projectRequirements?.toLowerCase().includes('custom') ||
    state.projectRequirements?.toLowerCase().includes('integration') ||
    state.projectRequirements?.toLowerCase().includes('migration') ||
    state.timeline?.toLowerCase().includes('urgent') ||
    state.additionalNotes?.toLowerCase().includes('speak') ||
    state.additionalNotes?.toLowerCase().includes('call') ||
    state.additionalNotes?.toLowerCase().includes('talk') ||
    state.additionalNotes?.toLowerCase().includes('human')
  );

  return { isComplex, missingInfo, matchedFeatures };
} 