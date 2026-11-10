import { getSession, signInWithGoogle } from './lib/auth.js';
import { getPet } from './lib/api.js';
import { LOW_STAT } from './lib/config.js';

const FAUCET_ALARM = 'faucet-ready';
const PET_ALARM = 'pet-check';
const READY_KEY = 'gp_faucet_ready_at';

chrome.runtime.onInstalled.addListener(() => {
  chrome.alarms.create(PET_ALARM, { periodInMinutes: 30 });
});

// Google sign-in runs here because the popup closes when the Google window takes focus.
// The result lands in storage (session or gp_auth_error), which the popup reads when reopened.
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg?.type !== 'google-sign-in') return false;
  chrome.storage.local.remove('gp_auth_error');
  signInWithGoogle()
    .then(() => sendResponse({ ok: true }))
    .catch(async (err) => {
      await chrome.storage.local.set({ gp_auth_error: err.message });
      sendResponse({ ok: false, error: err.message });
    });
  return true;
});

chrome.runtime.onStartup.addListener(async () => {
  chrome.alarms.create(PET_ALARM, { periodInMinutes: 30 });
  await scheduleFaucetAlarm();
});

// The popup writes the next claim time; the worker turns it into an alarm.
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'local' && READY_KEY in changes) scheduleFaucetAlarm();
});

async function scheduleFaucetAlarm() {
  const readyAt = (await chrome.storage.local.get(READY_KEY))[READY_KEY] || 0;
  await chrome.alarms.clear(FAUCET_ALARM);
  if (readyAt > Date.now()) {
    chrome.alarms.create(FAUCET_ALARM, { when: readyAt });
    chrome.action.setBadgeText({ text: '' });
  }
}

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === FAUCET_ALARM) {
    chrome.action.setBadgeBackgroundColor({ color: '#E0A526' });
    chrome.action.setBadgeText({ text: '!' });
    notify('faucet', 'Faucet ready', 'Your 5-minute Golden Paw faucet is ready to claim.');
  } else if (alarm.name === PET_ALARM) {
    await checkPet();
  }
});

async function checkPet() {
  if (!(await getSession())) return;
  try {
    const pet = await getPet();
    const low = ['hunger', 'happiness', 'energy'].filter((k) => Number(pet[k] ?? 100) < LOW_STAT);
    if (pet.sick || low.length) {
      const name = pet.name || 'Your Shiba';
      const what = pet.sick ? 'is feeling sick' : `needs attention (low ${low.join(', ')})`;
      notify('pet', `${name} ${what}`, 'Open Golden Paw to look after your pet.');
    }
  } catch {
    // offline or signed out; try again on the next check
  }
}

function notify(id, title, message) {
  chrome.notifications.create(id, {
    type: 'basic',
    iconUrl: 'icons/icon128.png',
    title,
    message,
    priority: 1,
  });
}

chrome.notifications.onClicked.addListener(async (id) => {
  chrome.notifications.clear(id);
  try {
    await chrome.action.openPopup();
  } catch {
    // openPopup needs a focused window; the badge still shows
  }
});
