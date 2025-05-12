import { NextRequest, NextResponse } from 'next/server';
import { generateAuthUrl, exchangeCodeForTokens } from '@/nodes/salesforce/auth';

// Store code verifiers temporarily (in production, use a secure storage solution)
const codeVerifiers = new Map<string, string>();

export async function GET(request: NextRequest) {
  try {
    // Check if this is a callback with an authorization code
    const searchParams = request.nextUrl.searchParams;
    const code = searchParams.get('code');
    const stateParam = searchParams.get('state');
    const error = searchParams.get('error');
    const error_description = searchParams.get('error_description');

    // If there's an error, handle it
    if (error) {
      return NextResponse.json(
        { error, error_description },
        { status: 400 }
      );
    }

    // If this is the callback with the code
    if (code && stateParam) {
      // Get the stored code verifier
      const codeVerifier = codeVerifiers.get(stateParam);
      if (!codeVerifier) {
        return NextResponse.json(
          { error: 'Invalid state parameter' },
          { status: 400 }
        );
      }

      try {
        // Exchange the code for tokens
        const tokens = await exchangeCodeForTokens(code, codeVerifier);
        
        // Clean up the stored code verifier
        codeVerifiers.delete(stateParam);

        // In a real application, you would securely store these tokens
        // For now, we'll just return them (not recommended for production)
        return NextResponse.json(tokens);
      } catch (error) {
        return NextResponse.json(
          { error: 'Failed to exchange code for tokens' },
          { status: 500 }
        );
      }
    }

    // If no code is present, start the OAuth flow
    const { authUrl, codeVerifier } = await generateAuthUrl();
    
    // Store the code verifier mapped to the state
    const generatedState = new URL(authUrl).searchParams.get('state');
    if (generatedState) {
      codeVerifiers.set(generatedState, codeVerifier);
    }

    // Redirect to the authorization URL
    return NextResponse.redirect(authUrl);
  } catch (error) {
    console.error('OAuth error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
} 