---
title: Microframework for building websites
---

[cannot](http://mietek.github.io/cannot/)
=========================================

Microframework for building websites.

Used in:

- [This website](http://mietek.github.io/cannot/) ([Source](https://github.com/mietek/cannot/))
- [My website](http://mietek.github.io/) ([Source](https://github.com/mietek/mietek-website/))
- [Least Fixed website](http://mietek.github.io/least-fixed-website/) ([Source](https://github.com/mietek/least-fixed-website/))
- [_bashmenot_ website](http://mietek.github.io/bashmenot-website/) ([Source](https://github.com/mietek/bashmenot-website/))
- [Halcyon website](http://mietek.github.io/halcyon-website/) ([Source](https://github.com/mietek/halcyon-website/))
- [Haskell on Heroku website](http://mietek.github.io/haskell-on-heroku-website/) ([Source](https://github.com/mietek/haskell-on-heroku-website/))
- [Motoworks Cambridge website](http://mietek.github.io/motoworks-website/) ([Source](https://github.com/mietek/motoworks-website/))


Usage
-----

Work in progress.  Not currently intended for public use.

```
$ ln -s bower_components/cannot/Makefile .
$ make
```


### Installation

Available as a [Bower](http://bower.io/) package.

```
$ bower install cannot
```


### Dependencies

Free software:

- [GNU _make_](http://gnu.org/software/make/) for building.
- [_pandoc_](http://johnmacfarlane.net/pandoc/) for generating pages.
- [Sass](http://sass-lang.com/) and [_clean-css_](https://github.com/jakubpawlowicz/clean-css/) for processing stylesheets.
- [_webpack_](http://webpack.github.io/) for bundling scripts.
- [AdvanceCOMP](http://advancemame.sourceforge.net/comp-readme.html) for recompressing archives.
- [ImageMagick](http://www.imagemagick.org/), [_jpegoptim_](https://github.com/tjko/jpegoptim/), and [OptiPNG](http://optipng.sourceforge.net/) for optimising images.
- [_fswatch_](https://github.com/emcrisostomo/fswatch/) and [BrowserSync](http://www.browsersync.io/) for live preview.
- [_ease-scroll_](https://github.com/mietek/ease-scroll/) for smooth scrolling.

```
$ brew install advancecomp fswatch imagemagick jpegoptim node optipng pandoc
$ gem install sass
$ npm install -g bower browser-sync clean-css webpack
```

Proprietary software:

- [Sketch](http://bohemiancoding.com/sketch/) for rebuilding logotypes, icons, and favicons.
- [Icon Slate](http://www.kodlian.com/apps/icon-slate/) for rebuilding favicons.


Support
-------

Please report any problems with _cannot_ on the [issue tracker](https://github.com/mietek/cannot/issues/).

Commercial support for _cannot_ is offered by [Least Fixed](http://leastfixed.com/), a functional software consultancy.

Need help?  Say <a id="hello">hello</a>.


License
-------

Made by [Miëtek Bak](http://mietek.io/).  Published under the <a id="license-link" href="https://github.com/mietek/license/blob/master/LICENSE.md">MIT X11 license</a>.


<script>
addEventListener('load', function () {
document.getElementById('hello').href = cannot.rot13('znvygb:uryyb@yrnfgsvkrq.pbz');
document.getElementById('license-link').href = 'license/';
});
</script>
