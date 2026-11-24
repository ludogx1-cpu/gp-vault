// Pro page: buy button, licence activation and deactivation.
(function () {
    const $ = id => document.getElementById(id);
    const price = GP_PRO.price;
    document.querySelectorAll('[data-pro-price]').forEach(el => { el.textContent = price; });

    const buy = $('buyPro');
    if (GP_PRO.checkoutUrl) {
        buy.href = GP_PRO.checkoutUrl;
        buy.target = '_blank';
    } else {
        buy.removeAttribute('href');
        buy.setAttribute('aria-disabled', 'true');
        buy.classList.add('cta-disabled');
        buy.textContent = 'Pro checkout opens soon';
        $('buyNote').textContent = 'Checkout isn\'t switched on yet. Check back shortly.';
    }

    function render() {
        const pro = GP_PRO.isPro();
        $('proActive').hidden = !pro;
        $('proInactive').hidden = pro;
        $('proEmail').textContent = pro && GP_PRO.email ? ` (${GP_PRO.email})` : '';
    }
    GP_PRO.onChange(render);
    render();

    $('activateForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = $('activateBtn');
        btn.disabled = true; btn.textContent = 'Checking…';
        $('activateMsg').textContent = '';
        const r = await GP_PRO.activate($('licenceKey').value);
        $('activateMsg').textContent = r.message;
        btn.disabled = false; btn.textContent = 'Unlock Pro';
        if (r.ok) $('licenceKey').value = '';
    });
    $('deactivateBtn').addEventListener('click', async () => {
        await GP_PRO.deactivate();
        $('activateMsg').textContent = 'Pro is deactivated on this device. Your key can be used on another device now.';
    });
})();
