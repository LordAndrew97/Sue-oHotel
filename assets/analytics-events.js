(function () {
  'use strict';

  function track(eventName, params) {
    if (typeof window.suenohotelTrack === 'function') {
      window.suenohotelTrack(eventName, params);
    }
  }

  document.addEventListener('click', function (event) {
    var whatsappLink = event.target.closest('a[href*="wa.me"]');
    if (whatsappLink) {
      track('whatsapp_click', {
        link_location: whatsappLink.id === 'wa' ? 'floating_button' : 'content'
      });
    }

    var productLink = event.target.closest('a[href*="productos/"]');
    if (productLink) {
      track('select_item', {
        item_id: productLink.getAttribute('href') || ''
      });
    }
  });

  document.addEventListener('submit', function (event) {
    if (event.target.id !== 'quote-form') return;
    track('generate_lead', {
      method: 'whatsapp',
      product: document.body.getAttribute('data-product') || 'general'
    });
  });
})();
