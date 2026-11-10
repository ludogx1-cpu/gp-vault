// Same Firebase web project and backend as the Golden Paw web app
// (lib/src/firebase_service.dart and lib/api_constants.dart).
export const FIREBASE_API_KEY = 'AIzaSyCDpj38AVvMY01EGKFtJo1YzNC8oUE6VZo';
export const API_BASE = 'https://golden-paw-vault.onrender.com';
export const SITE_URL = 'https://goldenpaw.dog';
export const CAPTCHA_ORIGIN = 'https://goldenpaw.dog';

// Firebase's Google web OAuth client (client_type 3 in android/app/google-services.json).
// Its authorized redirect URIs must include this extension's chrome.identity.getRedirectURL().
export const GOOGLE_WEB_CLIENT_ID = '163858364889-6b3gurkgtik76jque9ccq1dr9iqju9mb.apps.googleusercontent.com';

// Matches the 5 minute cooldown enforced in backend/src/services/faucetService.js.
export const FAUCET_COOLDOWN_MS = 5 * 60 * 1000;
export const LOW_STAT = 30;
