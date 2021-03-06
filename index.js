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
    document.addEventListener('touchstart', function () {});
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


(function () {
  var layout;
  var fontSize;
  var lineHeight;

  // TODO: Re-use the same values as _layout.sass somehow.
  var matchLayoutWidth = function () {
    if (window.matchMedia('(max-width: 719px)').matches) {
      layout = 'small';
      fontSize = 18;
      lineHeight = 24;
    } else if (window.matchMedia('(min-width: 720px) and (max-width: 1519px)').matches) {
      layout = 'medium';
      fontSize = 18;
      lineHeight = 24;
    } else if (window.matchMedia('(min-width: 1520px)').matches) {
      layout = 'large';
      fontSize = 24;
      lineHeight = 32;
    }
  };

  matchLayoutWidth();
  addEventListener('load', matchLayoutWidth);
  addEventListener('resize', matchLayoutWidth);

  exports.getLayout = function () {
    return layout;
  };
  exports.getFontSize = function () {
    return fontSize;
  };
  exports.getLineHeight = function () {
    return lineHeight;
  };
})();


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


exports.createBacklinkButton = function (target, title) {
  var backlinkButton = document.createElement('span');
  backlinkButton.className = 'backlink-button';
  var backlink = document.createElement('a');
  backlink.className = 'backlink';
  backlink.href = '#' + target;
  backlink.title = title;
  backlinkButton.appendChild(backlink);
  return backlinkButton;
};


exports.insertBacklinkButton = function (section) {
  var level = parseInt(section.className.replace(/level/, ''));
  var minLevel = parseInt(document.documentElement.dataset.minBackLinkLevel) || 2;
  var maxLevel = parseInt(document.documentElement.dataset.maxBackLinkLevel) || 2;
  var h2Target = document.documentElement.dataset.h2BackLinkTarget || 'top';
  if (!level || level < minLevel || level > maxLevel) {
    return;
  }
  var target, title;
  if (level <= 2) {
    target = h2Target;
    title = 'Top';
  } else {
    target = section.parentElement.id;
    var parentHeading = section.parentElement.getElementsByTagName('h' + (level - 1))[0];
    if (parentHeading === undefined) {
      return;
    }
    title = parentHeading.textContent;
  }
  var backlinkButton = exports.createBacklinkButton(target, title);
  var heading = section.getElementsByTagName('h' + level)[0];
  if (heading.nextSibling) {
    section.insertBefore(backlinkButton, heading.nextSibling);
  } else {
    section.appendChild(backlinkButton);
  }
};


exports.addSectionLinks = function () {
  var minLevel = parseInt(document.documentElement.dataset.minSectionLinkLevel) || 2;
  var maxLevel = parseInt(document.documentElement.dataset.maxSectionLinkLevel) || 4;
  var levels = [];
  for (var i = minLevel; i <= maxLevel; i += 1) {
    levels.push(i);
  }
  levels.forEach(function (level) {
    var sections = document.getElementsByClassName('level' + level);
    [].forEach.call(sections, function (section) {
      var heading = section.getElementsByTagName('h' + level)[0];
      if (heading) {
        var link = document.createElement('a');
        link.className = 'section-link';
        var target = section.id;
        var title = heading.textContent;
        link.href = '#' + target;
        link.title = title;
        link.appendChild(heading.replaceChild(link, heading.firstChild));
        exports.insertBacklinkButton(section);
      }
    });
  });
};


exports.insertToc = function (section, tocItem, insertBefore) {
  if (!section) {
    return;
  }
  var level = parseInt(section.className.replace(/level/, ''));
  var maxLevel = parseInt(document.documentElement.dataset.maxSectionTocLevel) || 2;
  if (!level || level > maxLevel) {
    return;
  }
  var toc = document.createElement('ul');
  toc.className = 'toc toc' + level + ' menu open';
  var tocItemCount = 0;
  var subsections = section.getElementsByClassName('level' + (level + 1));
  [].forEach.call(subsections, function (subsection) {
    var subheading = subsection.getElementsByTagName('h' + (level + 1))[0];
    if (!subheading) {
      return;
    }
    var tocItem = document.createElement('li');
    var link = document.createElement('a');
    link.href = '#' + subsection.id;
    link.title = subheading.textContent;
    [].forEach.call(subheading.childNodes, function (node) {
      link.appendChild(node.cloneNode(true));
    });
    tocItem.appendChild(link);
    toc.appendChild(tocItem);
    tocItemCount += 1;
    exports.insertToc(subsection, tocItem, insertBefore);
  });
  if (tocItemCount) {
    insertBefore(section, level, tocItem, toc);
  }
};


exports.addSectionToc = function () {
  var minLevel = parseInt(document.documentElement.dataset.minSectionTocLevel) || 1;
  var section1 = document.querySelectorAll('section.level' + minLevel)[0];
  exports.insertToc(section1, undefined, function (section, level, tocItem, toc) {
    var subsection = section.getElementsByClassName('level' + (level + 1))[0];
    var nav = document.createElement('nav');
    nav.appendChild(toc);
    section.classList.add('with-toc');
    section.insertBefore(nav, subsection);
  });
};


exports.addMainToc = function () {
  var minLevel = parseInt(document.documentElement.dataset.minSectionTocLevel) || 1;
  var section1 = document.querySelectorAll('section.level' + minLevel)[0];
  exports.insertToc(section1, undefined, function (section, level, tocItem, toc) {
    if (!tocItem) {
      var nav = document.getElementById('main-toc');
      nav.appendChild(toc);
      section1.classList.add('with-toc');
    } else {
      var p = document.createElement('p');
      [].forEach.call(tocItem.childNodes, function (node) {
        p.appendChild(node);
      });
      tocItem.appendChild(p);
      tocItem.appendChild(toc);
      tocItem.classList.add('with-subtoc');
    }
  });
};


exports.tweakListings = function () {
  var bold = new RegExp('(?:\\*\\*)([^\n]*)(?:\\*\\*)', 'g');
  var link = new RegExp('(https?://[^ \n]*?)(?=[ \n]|$|\\.\\.\\.)', 'g');
  var cmdLine = new RegExp('(^|\n|~ )([\\$#λ]) ([^\n]*?)(?=\n|$)', 'g');
  var listings = document.querySelectorAll('pre:not(.textmate-source):not(.with-tweaks) code');
  [].forEach.call(listings, function (listing) {
    listing.innerHTML = listing.innerText
      .replace(bold, '<b>$1</b>')
      .replace(link, '<a href="$1" target="_blank">$1</a>')
      .replace(cmdLine, '$1<span class="prompt">$2</span> <span class="input">$3</span>');
  });
};


exports.enableHeaderMenuButton = function () {
  var menuBar = document.getElementById('header-menu-bar');
  var menuButton = document.getElementById('header-button');
  var menu = document.getElementById('header-menu');
  if (menuBar && menuButton && menu) {
    menuButton.addEventListener('click', function (event) {
      event.preventDefault();
      menuBar.classList.toggle('open');
      menu.classList.toggle('open');
      menuButton.classList.toggle('open');
      var open = (localStorage['header-menu-open'] === 'true');
      if (open) {
        localStorage.removeItem('header-menu-open');
      } else {
        localStorage['header-menu-open'] = 'true';
      }
    });
  }
};


exports.enableToggleButtons = function () {
  var buttons = document.getElementsByClassName('toggle-button');
  [].forEach.call(buttons, function (button) {
    var target = document.getElementById(button.dataset.target);
    button.addEventListener('click', function (event) {
      event.preventDefault();
      button.classList.toggle('open');
      target.classList.toggle('open');
      var open = (localStorage[button.dataset.target] === 'true');
      if (open) {
        localStorage[button.dataset.target] = 'false';
      } else {
        localStorage[button.dataset.target] = 'true';
      }
    });
    if (localStorage[button.dataset.target] === 'true') {
      button.classList.add('open');
      target.classList.add('open');
    } else if (localStorage[button.dataset.target] === 'false') {
      button.classList.remove('open');
      target.classList.remove('open');
    }
  });
};


(function () {
  exports.detectTouch();
  exports.detectHairline();
  exports.disableTransitionsDuringResize();
  addEventListener('load', function () {
    if (document.documentElement.classList.contains('add-section-toc')) {
      exports.addSectionToc();
    } else if (document.documentElement.classList.contains('add-main-toc')) {
      exports.addMainToc();
    }
    exports.addSectionLinks();
    if (document.documentElement.classList.contains('tweak-listings')) {
      exports.tweakListings();
    }
    exports.enableHeaderMenuButton();
    exports.enableToggleButtons();
    easeScroll.applyToLocalLinks();
    var onTimeout = function () {
      document.documentElement.classList.remove('no-transition');
    };
    setTimeout(onTimeout, 100);
  });
})();
