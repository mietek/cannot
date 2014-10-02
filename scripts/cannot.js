'use strict';

var easeScroll = require('ease-scroll');

/* global scrollY */


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
    link.appendChild(document.createTextNode(sectionTitle));
    item.appendChild(link);
    toc.appendChild(item);

    var backlinkButtonWrapper = document.createElement('span');
    backlinkButtonWrapper.className = 'button-wrapper';
    var backlinkButton = document.createElement('span');
    backlinkButton.className = 'button';
    var backlink = document.createElement('a');
    backlink.className = 'backlink';
    backlink.href = '#' + container.id;
    backlink.title = containerTitle;
    backlink.appendChild(document.createTextNode('↩'));
    backlinkButton.appendChild(backlink);
    backlinkButtonWrapper.appendChild(backlinkButton);
    section.insertBefore(backlinkButtonWrapper, sectionHeading.nextSibling);

    itemCount += 1;
    exports.insertTocInSection(section);
  });
  if (itemCount) {
    var nav = document.createElement('nav');
    nav.appendChild(toc);
    if (window.insertToc !== undefined) {
      window.insertToc(nav, container);
    } else {
      container.insertBefore(nav, containerHeading.nextSibling);
    }
  }
};


(function () {
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
        }
      };
      setTimeout(onTimeout, 100);
    }
  });

  addEventListener('load', function () {
    document.documentElement.classList.remove('no-transition');
    [].forEach.call(document.getElementsByClassName('click-to-top'), function (element) {
      element.addEventListener('click', function (event) {
        event.preventDefault();
        easeScroll.scrollToOffset(0);
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

    if (document.documentElement.classList.contains('insert-toc')) {
      exports.insertTocInSection(document.getElementsByClassName('level1')[0]);
    }

    easeScroll.applyToLocalLinks();

    var localBase = location.origin + location.pathname;
    var links = document.links;
    [].forEach.call(links, function (link) {
      if (link.href === localBase) {
        link.addEventListener('click', function (event) {
          event.preventDefault();
          if (scrollY === 0) {
            link.classList.remove('shake');
            exports.restartAnimation(link);
            link.classList.add('shake');
          } else {
            easeScroll.scrollToOffset(0);
          }
        });
      }
    });
  });
})();
