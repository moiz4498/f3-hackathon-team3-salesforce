/**
 * @fileoverview Salesforce node for Lead qualification through natural conversation.
 */

import { z } from 'zod';
import type { Tool } from '../types';
import type { ConversationState } from './types';
import { createLead, escalateToCase } from './api';
import {
  extractInformation,
  generateResponse,
  analyzeRequirements,
  generateFallbackResponse
} from './utils';

// Parameter schema for the Salesforce node
const salesforceParamsSchema = z.object({
  input: z.string(),
  state: z.any().optional(),
  llmContext: z.any().optional()
});

// Salesforce Node
export const salesforceNode: Tool = {
  name: 'salesforce_node',
  description: 'Engages in natural conversation to understand requirements and qualify Salesforce leads.',
  parameters: salesforceParamsSchema,
  execute: async (params: z.infer<typeof salesforceParamsSchema>) => {
    // Initialize or retrieve conversation state
    const state: ConversationState = params.state || {
      stage: 'initial',
      context: ''
    };

    try {
      // Debug log for LLM context
      console.log('Salesforce node execution', {
        hasLLMContext: !!params.llmContext,
        stage: state.stage,
        input: params.input
      });

      // Extract information from user input
      const extractedInfo = await extractInformation(params.input, state, params.llmContext);
      
      // Update state with extracted information
      Object.assign(state, extractedInfo);

      // Update conversation stage based on current state
      if (state.stage === 'initial' && state.projectRequirements) {
        state.stage = 'gathering_requirements';
      } else if (
        state.stage === 'gathering_requirements' &&
        state.budget &&
        state.timeline
      ) {
        state.stage = 'contact_info';
      } else if (
        state.stage === 'contact_info' &&
        state.contactInfo?.email &&
        state.contactInfo?.company
      ) {
        state.stage = 'qualification';
      }

      // Analyze requirements and determine next steps
      const { isComplex, missingInfo } = analyzeRequirements(state);

      // Generate response based on current state
      let response: string;
      
      if (state.stage === 'qualification') {
        try {
          if (isComplex) {
            await escalateToCase(state);
            response = "Thank you for sharing your requirements. Given the complexity of your needs, I've arranged for our expert team to reach out to you directly. They'll be in touch soon to discuss your project in detail.";
          } else {
            await createLead(state);
            response = "Thank you for your interest! I've passed your information to our team. They'll reach out shortly to discuss how we can help implement your Salesforce solution.";
          }
          state.stage = 'complete';
        } catch (error) {
          console.error('Error creating lead/case:', error);
          response = "I apologize, but I encountered an issue while processing your information. Our team will reach out to you soon.";
        }
      } else {
        response = await generateResponse(state, params.llmContext);
      }

      return {
        response,
        state,
        shouldEnd: state.stage === 'complete'
      };
    } catch (error) {
      console.error('Error in Salesforce node:', error);
      return {
        response: generateFallbackResponse(state),
        state,
        shouldEnd: false
      };
    }
  }
};

// Export tools for registry
export const tools = {
  salesforce_node: salesforceNode
};