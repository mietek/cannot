'use strict';

var easeScroll = require('ease-scroll');


exports.rot13 = function (string) {
  return string
    .replace(/&lt;/g, '<')
    .replace(/[a-zA-Z]/g, function (c) {
      return String.fromCharCode((c <= 'Z' ? 90 : 122) >= (c = c.charCodeAt(0) + 13) ? c : c - 26);
    });
};


exports.ts = function (n) {
  return n * 1000 / 6;
};


exports.restartAnimation = function (target) {
  var display = target.style.display;
  target.style.display = 'none';
  (function (forceReflow) {
    return forceReflow;
  })(target.offsetHeight);
  target.style.display = display;
};


exports.addTocToSection = function (container) {
  if (!container) {
    return;
  }
  var level = parseInt(container.className.replace(/level/, ''));
  var containerHeading = container.getElementsByTagName('h' + level)[0];
  var containerTitle = containerHeading.textContent.replace(/↩/, '');

  var toc = document.createElement('ul');
  toc.className = 'toc toc' + level + ' menu open';
  var itemCount = 0;
  var sections = container.getElementsByClassName('level' + (level + 1));
  [].forEach.call(sections, function (section) {
    var sectionHeading = section.getElementsByTagName('h' + (level + 1))[0];
    if (!sectionHeading) {
      return;
    }
    var sectionTitle = sectionHeading.textContent;
    var item = document.createElement('li');
    var link = document.createElement('a');
    link.href = '#' + section.id;
    link.title = sectionTitle;
    link.appendChild(document.createTextNode(sectionTitle));
    item.appendChild(link);
    toc.appendChild(item);

    var backLinkButton = document.createElement('span');
    backLinkButton.className = 'backlink-button';
    var backLink = document.createElement('a');
    backLink.className = 'backlink';
    backLink.href = '#' + container.id;
    backLink.title = containerTitle;
    backLink.appendChild(document.createTextNode('↩'));
    backLinkButton.appendChild(backLink);
    section.insertBefore(backLinkButton, sectionHeading.nextSibling);

    itemCount += 1;
    exports.addTocToSection(section);
  });
  if (itemCount) {
    var nav = document.createElement('nav');
    nav.appendChild(toc);
    container.insertBefore(nav, containerHeading.nextSibling);
  }
};


(function () {
  var lastResizeT;

  addEventListener('resize', function () {
    lastResizeT = Date.now();
    if (!document.documentElement.classList.contains('no-transition')) {
      document.documentElement.classList.add('no-transition');
      var onTimeout = function () {
        if (Date.now() - lastResizeT < exports.ts(1)) {
          setTimeout(onTimeout, exports.ts(1));
        } else {
          document.documentElement.classList.remove('no-transition');
        }
      };
      setTimeout(onTimeout, exports.ts(1));
    }
  });

  addEventListener('load', function () {
    document.documentElement.classList.remove('no-transition');
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
        easeScroll.scrollToElementById('main', exports.ts(3));
      });
    });
  });
})();


(function () {
  if ('ontouchstart' in window) {
    document.documentElement.classList.add('touch');
  } else {
    document.documentElement.classList.add('no-touch');
  }

  addEventListener('load', function () {
    var headerMenuButton = document.getElementById('header-button');
    var headerMenu = document.getElementById('header-menu');
    if (headerMenuButton && headerMenu) {
      headerMenuButton.addEventListener('click', function (event) {
        event.preventDefault();
        headerMenu.classList.toggle('open');
        headerMenuButton.classList.toggle('open');
        var open = (localStorage['header-menu-open'] === 'true');
        if (open) {
          localStorage.removeItem('header-menu-open');
        } else {
          localStorage['header-menu-open'] = 'true';
        }
      });
    }

    if (document.body.classList.contains('toc')) {
      exports.addTocToSection(document.getElementsByClassName('level1')[0]);
    }

    easeScroll.applyToLocalLinks();
  });
})();
