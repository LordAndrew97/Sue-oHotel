(function () {
  'use strict';

  var CONSENT_KEY = 'suenohotel.analyticsConsent';
  var ACCEPTED = 'accepted';
  var REJECTED = 'rejected';
  var scriptElement = document.currentScript;
  var measurementId = scriptElement ? scriptElement.getAttribute('data-ga-measurement-id') : '';
  var privacyPolicyHref = scriptElement ? scriptElement.getAttribute('data-privacy-policy-href') : 'politica-de-privacidad.html';
  var cookiePolicyHref = scriptElement ? scriptElement.getAttribute('data-cookie-policy-href') : 'politica-de-cookies.html';

  function readConsent() {
    try {
      return window.localStorage.getItem(CONSENT_KEY);
    } catch (error) {
      return null;
    }
  }

  function saveConsent(value) {
    try {
      window.localStorage.setItem(CONSENT_KEY, value);
    } catch (error) {
      // The current choice still applies to this page if storage is unavailable.
    }
  }

  function prepareConsentState() {
    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () {
      window.dataLayer.push(arguments);
    };

    if (window.__suenohotelConsentPrepared) return;
    window.__suenohotelConsentPrepared = true;

    window.gtag('consent', 'default', {
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied'
    });
    window.gtag('consent', 'update', {
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'granted'
    });
  }

  function loadAnalytics() {
    if (!/^G-[A-Z0-9]+$/.test(measurementId)) return;
    if (window.__suenohotelGa4MeasurementId === measurementId) return;

    window.__suenohotelGa4MeasurementId = measurementId;
    prepareConsentState();

    var source = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(measurementId);
    var analyticsScript = document.querySelector('script[data-suenohotel-ga4]') ||
      document.querySelector('script[src="' + source + '"]');

    if (!analyticsScript) {
      analyticsScript = document.createElement('script');
      analyticsScript.async = true;
      analyticsScript.src = source;
      analyticsScript.setAttribute('data-suenohotel-ga4', measurementId);
      document.head.appendChild(analyticsScript);
    }

    window.gtag('js', new Date());
    window.gtag('config', measurementId, { send_page_view: true });
    window.__suenohotelAnalyticsReady = true;
  }

  function revokeAnalytics() {
    prepareConsentState();
    window.gtag('consent', 'update', {
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied'
    });
    window.__suenohotelAnalyticsReady = false;
    window.__suenohotelGa4MeasurementId = null;

    try {
      document.cookie.split(';').forEach(function (cookie) {
        var name = cookie.split('=')[0].trim();
        if (/^_(ga|gid|gat)/.test(name)) {
          document.cookie = name + '=; Max-Age=0; path=/';
        }
      });
    } catch (error) {
      // Consent is still denied even if the browser blocks cookie cleanup.
    }
  }

  window.suenohotelTrack = function (eventName, eventParams) {
    if (!window.__suenohotelAnalyticsReady || typeof window.gtag !== 'function') return;
    window.gtag('event', eventName, eventParams || {});
  };

  function closeBanner(banner) {
    banner.classList.remove('is-visible');
    banner.classList.add('is-closing');

    var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.setTimeout(function () {
      banner.remove();
    }, reducedMotion ? 0 : 300);
  }

  function showBanner() {
    var banner = document.createElement('section');
    banner.className = 'cookie-consent';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-modal', 'false');
    banner.setAttribute('aria-labelledby', 'cookie-consent-title');
    banner.setAttribute('aria-describedby', 'cookie-consent-description');
    banner.innerHTML =
      '<div class="cookie-consent__card">' +
        '<div class="cookie-consent__art" aria-hidden="true">' +
          '<svg viewBox="0 0 96 96" role="img">' +
            '<path d="M79 44c-10 0-18-8-18-18 0-3 .7-6 2-8A34 34 0 1 0 82 45l-3-1Z" fill="#E8B86A" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/>' +
            '<circle cx="37" cy="34" r="5" fill="#191932"/>' +
            '<circle cx="30" cy="59" r="4.5" fill="#191932"/>' +
            '<circle cx="54" cy="69" r="5" fill="#00767C"/>' +
            '<circle cx="55" cy="45" r="3.5" fill="#00767C"/>' +
          '</svg>' +
        '</div>' +
        '<div class="cookie-consent__content">' +
          '<p class="cookie-consent__eyebrow">Tu privacidad</p>' +
          '<h2 class="cookie-consent__title" id="cookie-consent-title">Una visita a tu medida</h2>' +
          '<p class="cookie-consent__text" id="cookie-consent-description">Usamos Google Analytics 4 para entender c&oacute;mo se utiliza la web y mejorar tu experiencia. Solo activaremos la medici&oacute;n si la aceptas.</p>' +
          '<p class="cookie-consent__links"><a href="' + cookiePolicyHref + '">Pol&iacute;tica de cookies</a><span aria-hidden="true">&middot;</span><a href="' + privacyPolicyHref + '">Privacidad</a></p>' +
        '</div>' +
        '<div class="cookie-consent__actions">' +
          '<button class="cookie-consent__button cookie-consent__button--reject" type="button" data-cookie-choice="reject">Rechazar</button>' +
          '<button class="cookie-consent__button cookie-consent__button--accept" type="button" data-cookie-choice="accept">Aceptar</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(banner);
    window.requestAnimationFrame(function () {
      banner.classList.add('is-visible');
    });

    banner.addEventListener('click', function (event) {
      var button = event.target.closest('[data-cookie-choice]');
      if (!button) return;

      var buttons = banner.querySelectorAll('[data-cookie-choice]');
      buttons.forEach(function (item) { item.disabled = true; });

      if (button.getAttribute('data-cookie-choice') === 'accept') {
        saveConsent(ACCEPTED);
        prepareConsentState();
        loadAnalytics();
      } else {
        saveConsent(REJECTED);
        revokeAnalytics();
      }

      closeBanner(banner);
    });
  }

  window.suenoHotelOpenConsent = function () {
    if (!document.querySelector('.cookie-consent')) showBanner();
  };

  var consent = readConsent();
  if (consent === ACCEPTED) {
    prepareConsentState();
    loadAnalytics();
  } else if (consent !== REJECTED) {
    showBanner();
  }
})();
