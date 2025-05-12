import crypto from 'crypto';

// OAuth Configuration
const CLIENT_ID = process.env.SALESFORCE_CLIENT_ID;
const REDIRECT_URI = process.env.SALESFORCE_REDIRECT_URI;
const SALESFORCE_BASE_URL = 'creative-wolf-q6biwj-dev-ed.trailblaze.my.salesforce-sites.com';

// Generate a random verifier string for PKCE
function generateCodeVerifier(): string {
  return crypto.randomBytes(32)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
    .substring(0, 128);
}

// Generate code challenge from verifier
async function generateCodeChallenge(verifier: string): Promise<string> {
  const hash = crypto.createHash('sha256')
    .update(verifier)
    .digest('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
  return hash;
}

// Generate the authorization URL with PKCE
export async function generateAuthUrl(): Promise<{ authUrl: string, codeVerifier: string }> {
  if (!CLIENT_ID || !REDIRECT_URI) {
    throw new Error('Missing required environment variables: SALESFORCE_CLIENT_ID or SALESFORCE_REDIRECT_URI');
  }

  const codeVerifier = generateCodeVerifier();
  const codeChallenge = await generateCodeChallenge(codeVerifier);

  const params = new URLSearchParams({
    response_type: 'code',
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
    state: crypto.randomBytes(16).toString('hex') // Add state parameter for security
  });

  const authUrl = `https://${SALESFORCE_BASE_URL}/services/oauth2/authorize?${params.toString()}`;
  
  return {
    authUrl,
    codeVerifier // This needs to be stored securely and used when exchanging the code for tokens
  };
}

// Exchange authorization code for tokens
export async function exchangeCodeForTokens(code: string, codeVerifier: string): Promise<{
  access_token: string;
  refresh_token: string;
  instance_url: string;
}> {
  if (!CLIENT_ID || !REDIRECT_URI) {
    throw new Error('Missing required environment variables: SALESFORCE_CLIENT_ID or SALESFORCE_REDIRECT_URI');
  }

  const params = new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    code: code,
    code_verifier: codeVerifier
  });

  const response = await fetch(`https://${SALESFORCE_BASE_URL}/services/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: params.toString()
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to exchange code for tokens: ${error}`);
  }

  return response.json();
}

// Refresh access token
export async function refreshAccessToken(refreshToken: string): Promise<{
  access_token: string;
  instance_url: string;
}> {
  if (!CLIENT_ID) {
    throw new Error('Missing required environment variable: SALESFORCE_CLIENT_ID');
  }

  const params = new URLSearchParams({
    grant_type: 'refresh_token',
    client_id: CLIENT_ID,
    refresh_token: refreshToken
  });

  const response = await fetch(`https://${SALESFORCE_BASE_URL}/services/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: params.toString()
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to refresh access token: ${error}`);
  }

  return response.json();
} 