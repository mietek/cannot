'use strict';

var easeScroll = require('ease-scroll');


exports.ts = function (n) {
  return n * 1000 / 6;
};


exports.rot13 = function (string) {
  return string
    .replace(/&lt;/g, '<')
    .replace(/[a-zA-Z]/g, function (c) {
      return String.fromCharCode((c <= 'Z' ? 90 : 122) >= (c = c.charCodeAt(0) + 13) ? c : c - 26);
    });
};


exports.restartAnimation = function (target) {
  var display = target.style.display;
  target.style.display = 'none';
  (function (forceReflow) {
    return forceReflow;
  })(target.offsetHeight);
  target.style.display = display;
};


(function () {
  var lastResizeT;

  addEventListener('resize', function () {
    lastResizeT = Date.now();
    if (!document.documentElement.classList.contains('resize')) {
      document.documentElement.classList.add('resize');
      var onTimeout = function () {
        if (Date.now() - lastResizeT < exports.ts(1)) {
          setTimeout(onTimeout, exports.ts(1));
        } else {
          document.documentElement.classList.remove('resize');
        }
      };
      setTimeout(onTimeout, exports.ts(1));
    }
  });

  addEventListener('load', function () {
    [].forEach.call(document.getElementsByClassName('click-to-shake'), function (element) {
      element.addEventListener('click', function (event) {
        event.preventDefault();
        element.classList.remove('shake');
        exports.restartAnimation(element);
        element.classList.add('shake');
      });
    });
    [].forEach.call(document.getElementsByClassName('click-to-top'), function (element) {
      element.addEventListener('click', function (event) {
        event.preventDefault();
        easeScroll.scrollToOffset(0, exports.ts(3));
      });
    });
    [].forEach.call(document.getElementsByClassName('click-to-main'), function (element) {
      element.addEventListener('click', function (event) {
        event.preventDefault();
        easeScroll.scrollToElementById('main');
      });
    });
  });
})();
