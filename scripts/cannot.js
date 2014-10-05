'use strict';

var easeScroll = require('ease-scroll');

/* global devicePixelRatio */


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


exports.detectTouch = function () {
  if ('ontouchstart' in window) {
    document.documentElement.classList.add('touch');
  } else {
    document.documentElement.classList.add('no-touch');
  }
};


exports.detectHairline = function () {
  var hairline = false;
  if (window.devicePixelRatio && devicePixelRatio >= 2) {
    var div = document.createElement('div');
    div.style.border = '.5px solid transparent';
    document.body.appendChild(div);
    if (div.offsetHeight === 1) {
      hairline = true;
    }
    document.body.removeChild(div);
  }
  if (hairline) {
    document.documentElement.classList.remove('no-hairline');
    document.documentElement.classList.add('hairline');
  } else {
    document.documentElement.classList.remove('hairline');
    document.documentElement.classList.add('no-hairline');
  }
};


exports.disableTransitionsDuringResize = function () {
  var lastResizeT;
  addEventListener('resize', function () {
    lastResizeT = Date.now();
    if (!document.documentElement.classList.contains('no-transition')) {
      document.documentElement.classList.add('no-transition');
      var onTimeout = function () {
        if (Date.now() - lastResizeT < 100) {
          setTimeout(onTimeout, 100);
        } else {
          document.documentElement.classList.remove('no-transition');
          exports.detectHairline();
        }
      };
      setTimeout(onTimeout, 100);
    }
  });
};


exports.insertTocInSection = function (container) {
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
    if (sectionHeading.firstChild.tagName === 'CODE') {
      var code = document.createElement('code');
      code.appendChild(document.createTextNode(sectionTitle));
      link.appendChild(code);
    } else {
      link.appendChild(document.createTextNode(sectionTitle));
    }
    item.appendChild(link);
    toc.appendChild(item);

    var sectionLink = document.createElement('a');
    sectionLink.className = 'section-link';
    sectionLink.href = '#' + section.id;
    sectionLink.title = sectionTitle;
    sectionLink.appendChild(sectionHeading.replaceChild(sectionLink, sectionHeading.firstChild));

    var backlinkButton = document.createElement('span');
    backlinkButton.className = 'backlink-button';
    var backlink = document.createElement('a');
    backlink.className = 'backlink';
    backlink.href = '#' + container.id;
    backlink.title = containerTitle;
    backlink.appendChild(document.createTextNode('↩'));
    backlinkButton.appendChild(backlink);
    if (sectionHeading.nextSibling) {
      section.insertBefore(backlinkButton, sectionHeading.nextSibling);
    } else {
      section.appendChild(backlinkButton);
    }

    itemCount += 1;
    exports.insertTocInSection(section);
  });
  if (itemCount) {
    var nav = document.createElement('nav');
    nav.appendChild(toc);
    container.classList.add('with-toc');
    container.insertBefore(nav, sections[0]);
  }
};


exports.enableHeaderMenuButton = function () {
  var headerMenuBar = document.getElementById('header-menu-bar');
  var headerMenuButton = document.getElementById('header-button');
  var headerMenu = document.getElementById('header-menu');
  if (headerMenuBar && headerMenuButton && headerMenu) {
    headerMenuButton.addEventListener('click', function (event) {
      event.preventDefault();
      headerMenuBar.classList.toggle('open');
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
};


(function () {
  exports.detectTouch();
  exports.detectHairline();
  exports.disableTransitionsDuringResize();
  addEventListener('load', function () {
    document.documentElement.classList.remove('no-transition');
    if (document.documentElement.classList.contains('insert-toc')) {
      exports.insertTocInSection(document.getElementsByClassName('level1')[0]);
    }
    exports.enableHeaderMenuButton();
    easeScroll.applyToLocalLinks();
  });
})();
