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
  if (!level || level < 2) {
    return;
  }
  var target, title;
  if (level === 2) {
    target = 'top';
    title = 'Top';
  } else {
    target = section.parentElement.id;
    title = section.parentElement.getElementsByTagName('h' + (level - 1))[0].textContent;
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
  var minSectionLinkLevel = document.documentElement.dataset.minSectionLinkLevel || 2;
  var maxSectionLinkLevel = document.documentElement.dataset.maxSectionLinkLevel || 6;
  var levels = [];
  for (var i = minSectionLinkLevel; i <= maxSectionLinkLevel; i += 1) {
    levels.push(i);
  }
  levels.forEach(function (level) {
    var sections = document.getElementsByClassName('level' + level);
    [].forEach.call(sections, function (section) {
      var heading = section.getElementsByTagName('h' + level)[0];
      if (heading) {
        var link = document.createElement('a');
        link.className = 'section-link';
        var target, title;
        if (level === 1) {
          target = 'top';
          title = 'Top';
        } else {
          target = section.id;
          title = heading.textContent;
        }
        link.href = '#' + target;
        link.title = title;
        link.appendChild(heading.replaceChild(link, heading.firstChild));
        exports.insertBacklinkButton(section);
      }
    });
  });
};


exports.insertSectionToc = function (container) {
  if (!container) {
    return;
  }
  var level = parseInt(container.className.replace(/level/, ''));
  var maxSectionTocLevel = document.documentElement.dataset.maxSectionTocLevel || 3;
  if (!level || level > maxSectionTocLevel) {
    return;
  }

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

    itemCount += 1;
    exports.insertSectionToc(section);
  });
  if (itemCount) {
    var nav = document.createElement('nav');
    nav.appendChild(toc);
    container.classList.add('with-toc');
    container.insertBefore(nav, sections[0]);
  }
};


exports.addSectionToc = function () {
  var minSectionTocLevel = document.documentElement.dataset.minSectionTocLevel || 1;
  exports.insertSectionToc(document.querySelectorAll('section.level' + minSectionTocLevel)[0]);
};


exports.tweakListings = function () {
  var listings = document.querySelectorAll('pre');
  [].forEach.call(listings, function (listing) {
    var code = listing.firstChild;
    if (code.tagName === 'CODE') {
      var text = code.firstChild;
      var lineStart = text.textContent.indexOf('$ ');
      var lineEnd;
      if (lineStart === -1) {
        return;
      }
      if (lineStart !== 0) {
        var atPrompt1 = text.splitText(lineStart);
        var userInput1 = document.createElement('span');
        userInput1.className = 'input';
        userInput1.appendChild(atPrompt1.previousSibling);
        atPrompt1.parentElement.insertBefore(userInput1, atPrompt1);
        text = atPrompt1;
      }
      while (true) {
        lineStart = text.textContent.indexOf('$ ');
        if (lineStart === -1) {
          break;
        }
        lineEnd = text.textContent.indexOf('\n', lineStart);
        if (lineEnd === -1) {
          lineEnd = text.textContent.length;
        }
        var atPrompt = text.splitText(lineStart);
        var afterPrompt = atPrompt.splitText(1);
        var prompt = document.createElement('span');
        prompt.className = 'prompt';
        prompt.appendChild(afterPrompt.previousSibling);
        afterPrompt.parentElement.insertBefore(prompt, afterPrompt);
        var atCommand = afterPrompt.splitText(1);
        var afterCommand = atCommand.splitText(lineEnd - lineStart - 2);
        var userInput = document.createElement('span');
        userInput.className = 'input';
        userInput.appendChild(afterCommand.previousSibling);
        afterCommand.parentElement.insertBefore(userInput, afterCommand);
        text = afterCommand;
      }
    }
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


(function () {
  exports.detectTouch();
  exports.detectHairline();
  exports.disableTransitionsDuringResize();
  addEventListener('load', function () {
    document.documentElement.classList.remove('no-transition');
    if (document.documentElement.classList.contains('add-section-toc')) {
      exports.addSectionToc();
    }
    exports.addSectionLinks();
    exports.tweakListings();
    exports.enableHeaderMenuButton();
    easeScroll.applyToLocalLinks();
  });
})();
