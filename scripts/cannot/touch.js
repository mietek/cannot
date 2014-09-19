'use strict';


(function () {
  if ('ontouchstart' in window) {
    document.documentElement.classList.add('touch');
  } else {
    document.documentElement.classList.add('no-touch');
  }

  addEventListener('load', function () {
    var headerMenuButton = document.getElementById('header-menu-button');
    var headerMenu = document.getElementById('header-menu');
    if (headerMenuButton && headerMenu) {
      headerMenuButton.addEventListener('click', function (event) {
        event.preventDefault();
        headerMenu.classList.toggle('open');
        headerMenuButton.classList.toggle('open');
      });
    }
  });
})();
