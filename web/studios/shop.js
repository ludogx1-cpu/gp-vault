/*
 * Golden Paw Studios — shop & services catalogue.
 *
 * HOW TO START SELLING SOMETHING
 * 1. In Stripe: Product catalogue → Payment Links → "+ New" → create the
 *    product at the price below. Under "After payment", choose
 *    "Don't show confirmation page" and redirect to:
 *        https://goldenpaw.dog/studios/thanks/
 * 2. Copy the link (it looks like https://buy.stripe.com/xxxxxxxx) and paste
 *    it into the `stripe` field of that item below.
 * 3. Rebuild and deploy. The button changes from "Coming soon" to "Buy now".
 *
 * Leave `stripe` empty ('') and the item shows as "Coming soon" with a
 * "Notify me" email button instead, so nothing ever links to a broken page.
 */
window.GP_SHOP = {
  contactEmail: 'goldenpaw.dogeadmin@gmail.com',

  products: [
    {
      id: 'wallpapers',
      icon: '🖼️',
      name: 'Shiba Wallpaper Pack',
      price: '£3',
      blurb: '12 Golden Paw Shiba wallpapers for phone and desktop, in light and dark styles.',
      stripe: '',
    },
    {
      id: 'planner',
      icon: '🗓️',
      name: 'Dog Care Planner',
      price: '£5',
      blurb: 'A printable planner for walks, feeding, vet visits, meds and training progress.',
      stripe: '',
    },
    {
      id: 'colouring',
      icon: '🖍️',
      name: 'Shiba Colouring & Activity Book',
      price: '£4',
      blurb: '30 printable pages of Golden Paw colouring, mazes and puzzles for all ages.',
      stripe: '',
    },
    {
      id: 'portrait',
      icon: '🎨',
      name: 'Custom Pet Portrait',
      price: '£15',
      blurb: 'Send us a photo of your dog and get a portrait back in the Golden Paw art style.',
      stripe: '',
    },
    {
      id: 'groomer-kit',
      icon: '✂️',
      name: 'Groomer & Dog Walker Starter Kit',
      price: '£12',
      blurb: 'Editable price list, booking form, client card and 20 social post templates.',
      stripe: '',
    },
  ],

  services: [
    {
      id: 'audit',
      icon: '🔍',
      name: 'Website Speed & SEO Audit',
      price: '£29',
      blurb: 'A plain-English report on why your site is slow or hard to find, with your top 5 fixes.',
      stripe: '',
    },
    {
      id: 'website',
      icon: '🌐',
      name: 'Small Business Website',
      price: '£249',
      blurb: 'A fast, mobile-friendly site live in 72 hours. Free homepage mock-up first.',
      // Usually paid after the client approves the preview, so this can stay
      // empty and you send the link by email instead.
      stripe: '',
    },
    {
      id: 'care-plan',
      icon: '🛟',
      name: 'Website Care Plan',
      price: '£19/mo',
      blurb: 'Hosting, small edits and uptime monitoring for your site. Cancel any time.',
      stripe: '',
    },
    {
      id: 'extension',
      icon: '🧩',
      name: 'Custom Chrome Extension',
      price: 'from £99',
      blurb: 'A browser tool that automates the boring parts of your day.',
      stripe: '',
    },
    {
      id: 'social',
      icon: '📣',
      name: 'Monthly Social Media Pack',
      price: '£79/mo',
      blurb: '20 branded posts with captions and hashtags, ready to post each month.',
      stripe: '',
    },
  ],
};

(function () {
  var shop = window.GP_SHOP;

  function mailto(subject) {
    return 'mailto:' + shop.contactEmail + '?subject=' + encodeURIComponent(subject);
  }

  function card(item, kind) {
    var live = !!item.stripe;
    var el = document.createElement('div');
    el.className = 'svc-card' + (live ? '' : ' soon');
    var badge = live ? '' : '<span class="ribbon soon-ribbon">COMING SOON</span>';
    var href = live
      ? item.stripe
      : mailto((kind === 'product' ? 'Notify me: ' : 'Enquiry: ') + item.name);
    var label = live
      ? (kind === 'product' ? 'Buy now' : 'Book now')
      : (kind === 'product' ? 'Notify me' : 'Ask about this');
    el.innerHTML =
      badge +
      '<div class="svc-icon">' + item.icon + '</div>' +
      '<h3></h3>' +
      '<div class="svc-price"></div>' +
      '<p></p>' +
      '<a class="btn ' + (live ? 'btn-primary' : 'btn-secondary') + '"></a>';
    el.querySelector('h3').textContent = item.name;
    el.querySelector('.svc-price').textContent = item.price;
    el.querySelector('p').textContent = item.blurb;
    var a = el.querySelector('a');
    a.textContent = label;
    a.href = href;
    if (live) { a.target = '_blank'; a.rel = 'noopener'; }
    return el;
  }

  function render(containerId, items, kind) {
    var box = document.getElementById(containerId);
    if (!box) return;
    items.forEach(function (item) { box.appendChild(card(item, kind)); });
  }

  // Buttons elsewhere on a page can opt in with data-stripe="<service id>":
  // when that service has a Stripe link, the button goes straight to checkout.
  function wireButtons() {
    var all = shop.products.concat(shop.services);
    document.querySelectorAll('[data-stripe]').forEach(function (a) {
      var item = all.find(function (i) { return i.id === a.getAttribute('data-stripe'); });
      if (item && item.stripe) {
        a.href = item.stripe;
        a.target = '_blank';
        a.rel = 'noopener';
      }
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    render('shop-products', shop.products, 'product');
    render('shop-services', shop.services, 'service');
    wireButtons();
  });
})();
