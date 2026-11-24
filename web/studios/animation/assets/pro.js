/*
 * Golden Paw Animation Creation Tool: Pro licence (one-off £11.99).
 *
 * Licence keys are issued by Lemon Squeezy when someone buys Pro. This file
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
    const API = 'https://api.lemonsqueezy.com/v1/licenses/';
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
        const body = new URLSearchParams(fields);
        const res = await fetch(API + endpoint, { method: 'POST', headers: { Accept: 'application/json' }, body });
        let data = {};
        try { data = await res.json(); } catch (e) {}
        return { ok: res.ok, data };
    }

    // The key must belong to our Pro product, not some other Lemon Squeezy product.
    function rightProduct(meta) {
        const want = cfg().productId;
        return !want || (meta && String(meta.product_id) === String(want));
    }

    async function activate(rawKey) {
        const key = String(rawKey || '').trim();
        if (!/^[A-Za-z0-9-]{16,}$/.test(key)) return { ok: false, message: 'That doesn\'t look like a licence key. It\'s in your purchase email from Lemon Squeezy.' };
        try {
            const { ok, data } = await post('activate', { license_key: key, instance_name: 'Golden Paw Animate (' + (navigator.platform || 'web') + ')' });
            if (!ok || !data.activated) {
                const msg = (data && data.error) || 'The licence key could not be activated.';
                if (/limit/i.test(msg)) return { ok: false, message: 'This key is already active on the maximum number of devices. Deactivate it on another device first, or contact support.' };
                if (/not found|invalid/i.test(msg)) return { ok: false, message: 'We couldn\'t find that licence key. Copy it exactly from your purchase email and try again.' };
                if (/expired|disabled|refunded/i.test(msg)) return { ok: false, message: 'That licence key is no longer active. If you think that\'s wrong, contact us.' };
                return { ok: false, message: msg.charAt(0).toUpperCase() + msg.slice(1) };
            }
            if (!rightProduct(data.meta)) return { ok: false, message: 'That key is for a different product.' };
            write({ key, instanceId: data.instance && data.instance.id, checkedAt: Date.now(), email: data.meta && data.meta.customer_email });
            emit();
            return { ok: true, message: 'Pro is unlocked on this device. Thank you!' };
        } catch (e) {
            return { ok: false, message: 'Couldn\'t reach the licence server. Check your connection and try again.' };
        }
    }

    async function deactivate() {
        const s = read();
        if (s && s.key && s.instanceId) {
            try { await post('deactivate', { license_key: s.key, instance_id: s.instanceId }); } catch (e) {}
        }
        write(null); emit();
    }

    // Quiet background re-check. A refund or disabled key turns Pro off; being offline does not.
    async function recheck() {
        const s = read();
        if (!s || !s.key) return;
        if ((Date.now() - (s.checkedAt || 0)) / 864e5 < RECHECK_DAYS) return;
        try {
            const { data } = await post('validate', { license_key: s.key, instance_id: s.instanceId || '' });
            if (data && data.valid && rightProduct(data.meta)) { s.checkedAt = Date.now(); write(s); }
            else if (data && data.valid === false) { write(null); }
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
