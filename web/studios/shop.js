/*
 * Golden Paw Studios — shop & services catalogue.
 *
 * Downloads: the Stripe Payment Link redirects buyers to the file after payment.
 * Keep download URLs ONLY in Stripe (this repo is public).
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
 *
 * Optional, shown on the card so buyers know what they're getting before checkout:
 *   details: ['PDF, 24 A4 pages', 'Edit in Canva (free account)', ...]
 *   licence: 'Who can use it, in one plain sentence.'
 *   preview: '/shop/previews/planner.png'  (an example page, e.g. filled in for a fictional dog)
 * Products you can buy now are listed first.
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
      // TODO(owner): fill in so buyers can check the file works for them, e.g.
      // details: ['PDF, NN A4 pages', 'Print at home, colour or black and white'],
      details: [],
      licence: 'For you and your own dogs.',
      stripe: 'https://buy.stripe.com/5kQfZjcvq6X85Ba3lV0gw06',
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
      // TODO(owner): add the file type, page count and the software needed to edit it.
      details: [],
      licence: 'Business licence included: add your business name and logo, and use it with as many of your own clients as you like. Please don\'t resell or share the blank templates.',
      stripe: 'https://buy.stripe.com/bJeaEZ0MI4P08Nme0z0gw07',
    },
  ],

  services: [
    {
      id: 'audit',
      icon: '🔍',
      name: 'Website Speed & SEO Audit',
      price: '£29',
      blurb: 'A plain-English report on why your site is slow or hard to find, with your top 5 fixes.',
      stripe: 'https://buy.stripe.com/cNicN7ani3KW3t22hR0gw01',
    },
    {
      id: 'website',
      icon: '🌐',
      name: 'Small Business Website',
      price: '£249',
      blurb: 'A fast, mobile-friendly site live in 72 hours. Free homepage mock-up first.',
      // Usually paid after the client approves the preview, so this can stay
      // empty and you send the link by email instead.
      // Live link, sent by email once the client approves their preview:
      // https://buy.stripe.com/aFafZjfHCa9k5Ba7Cb0gw02
      stripe: '',
    },
    {
      id: 'care-plan',
      icon: '🛟',
      name: 'Website Care Plan',
      price: '£19/mo',
      blurb: 'Hosting, small edits and uptime monitoring for your site. Cancel any time.',
      stripe: 'https://buy.stripe.com/28E3cx52Y5T45Ba2hR0gw03',
    },
    {
      id: 'extension',
      icon: '🧩',
      name: 'Custom Chrome Extension',
      price: 'from £99',
      blurb: 'A browser tool that automates the boring parts of your day.',
      stripe: 'https://buy.stripe.com/14A8wRcvq3KW5Ba6y70gw04',
    },
    {
      id: 'social',
      icon: '📣',
      name: 'Monthly Social Media Pack',
      price: '£79/mo',
      blurb: '20 branded posts with captions and hashtags, ready to post each month.',
      stripe: 'https://buy.stripe.com/8x228tdzuepA6FebSr0gw05',
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
    var btn = el.querySelector('a.btn');
    if (item.preview) {
      var img = document.createElement('img');
      img.src = item.preview; img.loading = 'lazy'; img.className = 'shop-preview';
      img.alt = 'Example page from ' + item.name;
      el.insertBefore(img, el.querySelector('p'));
    }
    if (item.details && item.details.length) {
      var ul = document.createElement('ul');
      ul.className = 'shop-details';
      item.details.forEach(function (d) { var li = document.createElement('li'); li.textContent = d; ul.appendChild(li); });
      el.insertBefore(ul, btn);
    }
    if (item.licence) {
      var lic = document.createElement('p');
      lic.className = 'shop-licence';
      lic.textContent = item.licence;
      el.insertBefore(lic, btn);
    }
    var a = el.querySelector('a');
    a.textContent = label;
    a.href = href;
    if (live) { a.target = '_blank'; a.rel = 'noopener'; }
    return el;
  }

  function render(containerId, items, kind) {
    var box = document.getElementById(containerId);
    if (!box) return;
    // Things you can buy right now come first; "coming soon" items follow.
    items.filter(function (i) { return i.stripe; }).concat(items.filter(function (i) { return !i.stripe; }))
      .forEach(function (item) { box.appendChild(card(item, kind)); });
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
