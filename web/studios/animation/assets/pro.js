/*
 * Golden Paw Animation Creation Tool: Pro licence (one-off £11.99).
 *
 * Licence keys are issued by Polar (polar.sh) when someone buys Pro. This file
 * activates a key on this device, remembers it, and re-checks it now and then.
 * Configure the product in public/assets/site.js → SITE_CONFIG.pro.
 *
 *   GP_PRO.isPro()                → true/false
 *   await GP_PRO.activate(key)    → { ok, message }
 *   await GP_PRO.deactivate()
 *   GP_PRO.onChange(fn)
 */
window.GP_PRO = (function () {
    const STORE = 'gp-pro';
    // Polar's public licence-key endpoints: made for apps and browsers, no secret needed.
    const API = 'https://api.polar.sh/v1/customer-portal/license-keys/';
    const RECHECK_DAYS = 7;     // re-validate online this often
    const OFFLINE_GRACE_DAYS = 30; // keep Pro working offline this long after the last good check
    const listeners = [];

    const cfg = () => (window.SITE_CONFIG && window.SITE_CONFIG.pro) || {};
    function read() { try { return JSON.parse(localStorage.getItem(STORE) || 'null'); } catch (e) { return null; } }
    function write(v) { try { v ? localStorage.setItem(STORE, JSON.stringify(v)) : localStorage.removeItem(STORE); } catch (e) {} }
    function emit() { listeners.forEach(fn => { try { fn(isPro()); } catch (e) {} }); document.documentElement.classList.toggle('is-pro', isPro()); }

    function isPro() {
        const s = read();
        if (!s || !s.key || !s.instanceId) return false;
        const days = (Date.now() - (s.checkedAt || 0)) / 864e5;
        return days <= OFFLINE_GRACE_DAYS;
    }

    async function post(endpoint, fields) {
        const res = await fetch(API + endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
            body: JSON.stringify(Object.assign({ organization_id: cfg().organizationId }, fields))
        });
        let data = {};
        try { data = await res.json(); } catch (e) { /* 204 or not JSON */ }
        return { ok: res.ok, status: res.status, data };
    }

    // The key must come from our Pro licence benefit, not another Polar product.
    function rightProduct(lk) {
        const want = cfg().benefitId;
        return !want || !lk || !lk.benefit_id || String(lk.benefit_id) === String(want);
    }

    function deviceLabel() {
        const where = window.GP_IS_DESKTOP ? 'desktop app' : 'browser';
        return ('Golden Paw Animate (' + where + ', ' + (navigator.platform || 'web') + ')').slice(0, 100);
    }

    async function activate(rawKey) {
        const key = String(rawKey || '').trim();
        if (!/^[A-Za-z0-9-]{8,}$/.test(key)) return { ok: false, message: 'That doesn\'t look like a licence key. It starts with GPAW and is on your Polar order confirmation.' };
        if (!cfg().organizationId) return { ok: false, message: 'Pro activation isn\'t switched on yet. Please try again shortly.' };
        try {
            const r = await post('activate', { key, label: deviceLabel() });
            if (!r.ok) {
                const msg = String((r.data && (r.data.detail || r.data.error)) || '');
                if (r.status === 404) return { ok: false, message: 'We couldn\'t find that licence key. Copy it exactly from your order confirmation and try again.' };
                if (/limit/i.test(msg)) return { ok: false, message: 'This key is already active on the maximum number of devices (3). Deactivate it on another device first, or contact support.' };
                if (r.status === 403) return { ok: false, message: 'That licence key is no longer active. If you think that\'s wrong, contact us.' };
                return { ok: false, message: 'The licence key could not be activated' + (msg ? ': ' + msg : '.') };
            }
            // Confirm the key belongs to our Pro benefit (Polar checks this server-side).
            const activationId = r.data.id;
            const v = await post('validate', { key, activation_id: activationId, benefit_id: cfg().benefitId || undefined });
            if (!v.ok || !rightProduct(v.data)) {
                try { await post('deactivate', { key, activation_id: activationId }); } catch (e) {}
                return { ok: false, message: v.status === 404 ? 'That key is for a different product.' : 'The licence key could not be checked. Please try again.' };
            }
            const email = (v.data.customer && v.data.customer.email) || null;
            write({ key, instanceId: activationId, checkedAt: Date.now(), email });
            emit();
            return { ok: true, message: 'Pro is unlocked on this device. Thank you!' };
        } catch (e) {
            return { ok: false, message: 'Couldn\'t reach the licence server. Check your connection and try again.' };
        }
    }

    async function deactivate() {
        const s = read();
        if (s && s.key && s.instanceId) {
            try { await post('deactivate', { key: s.key, activation_id: s.instanceId }); } catch (e) {}
        }
        write(null); emit();
    }

    // Quiet background re-check. A refund or disabled key turns Pro off; being offline does not.
    async function recheck() {
        const s = read();
        if (!s || !s.key) return;
        if ((Date.now() - (s.checkedAt || 0)) / 864e5 < RECHECK_DAYS) return;
        try {
            const r = await post('validate', { key: s.key, activation_id: s.instanceId || undefined, benefit_id: cfg().benefitId || undefined });
            if (r.ok && r.data && r.data.status === 'granted' && rightProduct(r.data)) { s.checkedAt = Date.now(); write(s); }
            else if (r.status === 404 || (r.ok && r.data && r.data.status && r.data.status !== 'granted')) { write(null); }
            emit();
        } catch (e) { /* offline: keep Pro until the grace period ends */ }
    }

    function onChange(fn) { listeners.push(fn); }

    document.documentElement.classList.toggle('is-pro', isPro());
    if (!/^(chrome|moz|safari-web)-extension:$/.test(location.protocol)) setTimeout(recheck, 3000);

    return {
        isPro, activate, deactivate, onChange,
        get email() { const s = read(); return s && s.email; },
        get checkoutUrl() { return cfg().checkoutUrl || ''; },
        get price() { return cfg().price || '£11.99'; }
    };
})();
