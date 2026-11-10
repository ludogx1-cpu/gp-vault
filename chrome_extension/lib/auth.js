// Firebase Auth over its REST API, so no remotely hosted SDK is needed (MV3 forbids remote code).
import { FIREBASE_API_KEY, GOOGLE_WEB_CLIENT_ID } from './config.js';

const IDT = 'https://identitytoolkit.googleapis.com/v1';
const STS = 'https://securetoken.googleapis.com/v1/token';
const KEY = 'gp_session';

async function idt(path, body) {
  const res = await fetch(`${IDT}/${path}?key=${FIREBASE_API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(friendlyAuthError(data?.error?.message));
  return data;
}

function friendlyAuthError(code = '') {
  if (code.startsWith('INVALID_LOGIN_CREDENTIALS') || code.startsWith('INVALID_PASSWORD') || code.startsWith('EMAIL_NOT_FOUND')) {
    return 'Wrong email or password. If you use Google on goldenpaw.dog, use "Sign in with Google" above.';
  }
  if (code.startsWith('TOO_MANY_ATTEMPTS')) return 'Too many attempts. Try again later.';
  if (code.startsWith('USER_DISABLED')) return 'This account has been disabled.';
  if (code.startsWith('EMAIL_EXISTS')) return 'An account with this email already exists.';
  if (code.startsWith('WEAK_PASSWORD')) return 'Password must be at least 6 characters.';
  return code ? code.replace(/_/g, ' ').toLowerCase() : 'Sign-in failed.';
}

async function save(session) {
  await chrome.storage.local.set({ [KEY]: session });
  return session;
}

export async function getSession() {
  return (await chrome.storage.local.get(KEY))[KEY] || null;
}

export async function signIn(email, password) {
  return startSession(await idt('accounts:signInWithPassword', { email, password, returnSecureToken: true }));
}

// Google sign-in: get a Google ID token in a Chrome auth window, then exchange it with Firebase.
export async function signInWithGoogle() {
  const nonce = crypto.randomUUID();
  const url = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  url.search = new URLSearchParams({
    client_id: GOOGLE_WEB_CLIENT_ID,
    response_type: 'id_token',
    redirect_uri: chrome.identity.getRedirectURL(),
    scope: 'openid email profile',
    nonce,
    prompt: 'select_account',
  });

  let redirect;
  try {
    redirect = await chrome.identity.launchWebAuthFlow({ url: url.href, interactive: true });
  } catch (err) {
    const msg = String(err?.message || err);
    if (/cancel|closed|did not approve/i.test(msg)) throw new Error('Google sign-in was cancelled.');
    throw new Error('Google sign-in is not set up for this extension yet.');
  }
  const params = new URLSearchParams(new URL(redirect).hash.slice(1));
  const idToken = params.get('id_token');
  if (!idToken) throw new Error(params.get('error_description') || params.get('error') || 'Google sign-in failed.');

  return startSession(await idt('accounts:signInWithIdp', {
    postBody: new URLSearchParams({ id_token: idToken, providerId: 'google.com' }).toString(),
    requestUri: chrome.identity.getRedirectURL(),
    returnSecureToken: true,
    returnIdpCredential: true,
  }));
}

async function startSession(d) {
  if (!d.idToken) throw new Error(d.errorMessage || 'Sign-in failed. Try again on goldenpaw.dog first.');
  const session = {
    uid: d.localId,
    email: d.email,
    idToken: d.idToken,
    refreshToken: d.refreshToken,
    expiresAt: Date.now() + Number(d.expiresIn) * 1000,
  };
  session.emailVerified = await lookupVerified(session.idToken);
  return save(session);
}

// Also gives Google-only accounts a password they can use in the extension.
export async function sendPasswordReset(email) {
  await idt('accounts:sendOobCode', { requestType: 'PASSWORD_RESET', email });
}

export async function signOut() {
  await chrome.storage.local.remove(KEY);
}

async function lookupVerified(idToken) {
  const d = await idt('accounts:lookup', { idToken });
  return Boolean(d.users?.[0]?.emailVerified);
}

export async function resendVerification() {
  const token = await getIdToken();
  await idt('accounts:sendOobCode', { requestType: 'VERIFY_EMAIL', idToken: token });
}

// Re-reads email verification after the user clicks the link in their inbox.
export async function refreshVerified() {
  const s = await getSession();
  if (!s) return false;
  const fresh = await refresh(s, true);
  fresh.emailVerified = await lookupVerified(fresh.idToken);
  await save(fresh);
  return fresh.emailVerified;
}

async function refresh(s, force = false) {
  if (!force && s.expiresAt - Date.now() > 60_000) return s;
  const res = await fetch(`${STS}?key=${FIREBASE_API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: s.refreshToken }),
  });
  const d = await res.json();
  if (!res.ok) {
    await signOut();
    throw new Error('Your session expired. Please sign in again.');
  }
  return save({
    ...s,
    idToken: d.id_token,
    refreshToken: d.refresh_token,
    expiresAt: Date.now() + Number(d.expires_in) * 1000,
  });
}

export async function getIdToken() {
  const s = await getSession();
  if (!s) throw new Error('Not signed in.');
  return (await refresh(s)).idToken;
}
