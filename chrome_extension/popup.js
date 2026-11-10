import { signIn, signOut, getSession, resendVerification, refreshVerified, sendPasswordReset } from './lib/auth.js';
import { getPet, petAction, claimToVault, claimToFaucetPay, cooldownFromError } from './lib/api.js';
import { SITE_URL, CAPTCHA_ORIGIN, FAUCET_COOLDOWN_MS } from './lib/config.js';

const READY_KEY = 'gp_faucet_ready_at';
const PREFS_KEY = 'gp_prefs';

const $ = (id) => document.getElementById(id);
let captcha = null; // { token, provider }
let tick = null;

// Same stage -> art mapping as PetSpriteWidget.getImageAssetForStage in the app.
const STAGE_ART = {
  egg: 'shiba_egg', baby: 'shiba_baby', toddler: 'shiba_teen', puppy: 'shiba_puppy',
  child: 'shiba_child', teen: 'shiba_young_adult', young_adult: 'shiba_young_adult',
  adult: 'shiba_adult', old_dog: 'old_dog',
};

function say(el, text, kind = '') {
  el.textContent = text;
  el.className = `msg ${kind}`;
}

function openSite(e) {
  e.preventDefault();
  chrome.tabs.create({ url: `${SITE_URL}/` });
}

// ---------- views ----------

async function render() {
  const session = await getSession();
  $('login-view').classList.toggle('hidden', Boolean(session));
  $('main-view').classList.toggle('hidden', !session);
  $('signout').classList.toggle('hidden', !session);
  if (!session) {
    const { gp_auth_error: authError } = await chrome.storage.local.get('gp_auth_error');
    if (authError) say($('login-msg'), authError, 'err');
    $('email').focus();
    return;
  }
  chrome.storage.local.remove('gp_auth_error');
  chrome.action.setBadgeText({ text: '' });
  await loadPrefs();
  updateVerifyRow(session);
  startTimer();
  loadPet();
}

$('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  $('login-btn').disabled = true;
  say($('login-msg'), 'Signing in…');
  try {
    await signIn($('email').value.trim(), $('password').value);
    $('password').value = '';
    say($('login-msg'), '');
    await render();
  } catch (err) {
    say($('login-msg'), err.message, 'err');
  } finally {
    $('login-btn').disabled = false;
  }
});

$('google-btn').addEventListener('click', async () => {
  $('google-btn').disabled = true;
  say($('login-msg'), 'Opening Google… if this pop-up closes, click the paw icon again once you have signed in.');
  // The popup may close while the Google window has focus; storage.onChanged re-renders if it stays open.
  const res = await chrome.runtime.sendMessage({ type: 'google-sign-in' });
  $('google-btn').disabled = false;
  if (res?.ok) render();
  else say($('login-msg'), res?.error || 'Google sign-in failed.', 'err');
});

$('forgot').addEventListener('click', async () => {
  const email = $('email').value.trim();
  if (!email || !$('email').checkValidity()) {
    say($('login-msg'), 'Type your email address first.', 'err');
    $('email').focus();
    return;
  }
  $('forgot').disabled = true;
  try {
    await sendPasswordReset(email);
    say($('login-msg'), `If ${email} has a Golden Paw account, a link to set your password is on its way. Check spam too.`, 'ok');
  } catch (err) {
    say($('login-msg'), err.message, 'err');
  } finally {
    $('forgot').disabled = false;
  }
});

$('signout').addEventListener('click', async () => {
  await signOut();
  clearInterval(tick);
  render();
});

$('site-link').addEventListener('click', openSite);
$('open-site').addEventListener('click', openSite);

// ---------- pet ----------

function showPet(pet) {
  const stage = pet.stage || 'puppy';
  $('pet-img').src = `pets/${STAGE_ART[stage] || 'shiba_puppy'}.png`;
  $('pet-name').textContent = pet.name || 'Your Shiba';
  $('pet-stage').textContent = stage.replace('_', ' ');
  for (const k of ['hunger', 'happiness', 'energy']) {
    const v = Math.round(Number(pet[k] ?? 0));
    $(k).value = v;
    $(k).title = `${v} / 100`;
  }
}

async function loadPet() {
  try {
    showPet(await getPet());
  } catch (err) {
    say($('pet-msg'), err.message, 'err');
  }
}

for (const btn of document.querySelectorAll('[data-action]')) {
  btn.addEventListener('click', async () => {
    const buttons = document.querySelectorAll('[data-action]');
    buttons.forEach((b) => (b.disabled = true));
    say($('pet-msg'), '…');
    try {
      const res = await petAction(btn.dataset.action);
      say($('pet-msg'), res.message || 'Done!', 'ok');
      await loadPet();
    } catch (err) {
      say($('pet-msg'), err.message, 'err');
    } finally {
      buttons.forEach((b) => (b.disabled = false));
    }
  });
}

// ---------- faucet ----------

async function loadPrefs() {
  const prefs = (await chrome.storage.local.get(PREFS_KEY))[PREFS_KEY] || {};
  const mode = prefs.mode || 'vault';
  document.querySelector(`input[name="mode"][value="${mode}"]`).checked = true;
  $('address').value = prefs.address || '';
  $('captcha-provider').value = prefs.provider || 'turnstile';
  $('address-row').classList.toggle('hidden', mode !== 'faucetpay');
}

async function savePrefs() {
  await chrome.storage.local.set({
    [PREFS_KEY]: { mode: currentMode(), address: $('address').value.trim(), provider: $('captcha-provider').value },
  });
}

const currentMode = () => document.querySelector('input[name="mode"]:checked').value;

for (const r of document.querySelectorAll('input[name="mode"]')) {
  r.addEventListener('change', async () => {
    $('address-row').classList.toggle('hidden', currentMode() !== 'faucetpay');
    await savePrefs();
    updateVerifyRow(await getSession());
    updateClaimButton();
  });
}
$('address').addEventListener('input', () => { savePrefs(); updateClaimButton(); });
$('captcha-provider').addEventListener('change', () => { savePrefs(); loadCaptcha(); });

function updateVerifyRow(session) {
  const needs = currentMode() === 'faucetpay' && session && !session.emailVerified;
  $('verify-row').classList.toggle('hidden', !needs);
}

$('resend').addEventListener('click', async () => {
  try {
    await resendVerification();
    say($('faucet-msg'), 'Verification email sent. Check your inbox.', 'ok');
  } catch (err) {
    say($('faucet-msg'), err.message, 'err');
  }
});

$('recheck').addEventListener('click', async () => {
  try {
    const ok = await refreshVerified();
    updateVerifyRow(await getSession());
    say($('faucet-msg'), ok ? 'Email verified.' : 'Not verified yet.', ok ? 'ok' : 'err');
    updateClaimButton();
  } catch (err) {
    say($('faucet-msg'), err.message, 'err');
  }
});

// captcha.html on goldenpaw.dog posts the solved token to its parent window.
window.addEventListener('message', (e) => {
  if (e.origin !== CAPTCHA_ORIGIN) return;
  try {
    const data = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
    const token = data.token || data.captcha_token || data.turnstile_token;
    if (token) {
      captcha = { token, provider: data.provider || $('captcha-provider').value };
      updateClaimButton();
    }
  } catch {
    // not ours
  }
});

function loadCaptcha() {
  captcha = null;
  const provider = $('captcha-provider').value;
  $('captcha').src = `${CAPTCHA_ORIGIN}/captcha.html?type=${provider}&dark=true&t=${Date.now()}`;
  updateClaimButton();
}

async function readyAt() {
  return (await chrome.storage.local.get(READY_KEY))[READY_KEY] || 0;
}

async function startTimer() {
  clearInterval(tick);
  let wasWaiting = null;
  const step = async () => {
    const left = (await readyAt()) - Date.now();
    const waiting = left > 0;
    if (waiting) {
      const s = Math.ceil(left / 1000);
      $('countdown').textContent = `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
    }
    if (waiting !== wasWaiting) {
      $('timer').classList.toggle('hidden', !waiting);
      $('captcha-box').classList.toggle('hidden', waiting);
      if (!waiting) loadCaptcha();
      wasWaiting = waiting;
      updateClaimButton(waiting);
    }
  };
  await step();
  tick = setInterval(step, 1000);
}

let claiming = false;
async function updateClaimButton(waiting) {
  if (waiting === undefined) waiting = (await readyAt()) > Date.now();
  const btn = $('claim');
  const session = await getSession();
  const fp = currentMode() === 'faucetpay';
  let label = fp ? 'Claim DOGE to FaucetPay' : 'Claim to Vault';
  let ok = true;
  if (waiting) { label = 'Waiting for cooldown'; ok = false; }
  else if (!captcha) { label = 'Solve the captcha'; ok = false; }
  else if (fp && !$('address').value.trim()) { label = 'Enter your FaucetPay address'; ok = false; }
  else if (fp && !session?.emailVerified) { label = 'Verify your email first'; ok = false; }
  if (claiming) { label = 'Claiming…'; ok = false; }
  btn.textContent = label;
  btn.disabled = !ok;
}

$('claim').addEventListener('click', async () => {
  if (!captcha) return;
  claiming = true;
  updateClaimButton();
  say($('faucet-msg'), 'Verifying & sending…');
  const solved = captcha;
  captcha = null;
  try {
    let msg;
    if (currentMode() === 'faucetpay') {
      const res = await claimToFaucetPay($('address').value.trim(), solved);
      msg = `Sent ${Number(res.amount || 0).toFixed(8)} DOGE to FaucetPay! (+10 XP)`;
    } else {
      const res = await claimToVault(solved);
      msg = `Claimed ${Number(res.earned || 0).toFixed(8)} DOGE to your Vault! (+10 XP)`;
    }
    say($('faucet-msg'), msg, 'ok');
    await chrome.storage.local.set({ [READY_KEY]: Date.now() + FAUCET_COOLDOWN_MS });
    loadPet();
  } catch (err) {
    say($('faucet-msg'), err.message, 'err');
    const wait = cooldownFromError(err.message);
    if (wait) await chrome.storage.local.set({ [READY_KEY]: Date.now() + wait });
    else loadCaptcha();
  } finally {
    claiming = false;
    updateClaimButton();
  }
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'local' && READY_KEY in changes) startTimer();
});

render();
