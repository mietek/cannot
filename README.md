[_cannot_](http://cannot.mietek.io/)
====================================

_cannot_ is not a web framework.

> _“Those who do not understand Unix are condemned to reinvent it, poorly.”_  
> — [Henry Spencer](http://en.wikipedia.org/wiki/Henry_Spencer)


Examples
--------

- [Haskell on Heroku website](http://haskellonheroku.com/) ([Source](https://github.com/mietek/haskell-on-heroku-website/))
- [Halcyon website](http://halcyon.sh/) ([Source](https://github.com/mietek/halcyon-website/))
- [_bashmenot_ website](http://bashmenot.mietek.io/) ([Source](https://github.com/mietek/bashmenot-website/))
- [_cannot_ website](http://cannot.mietek.io/) ([Source](https://github.com/mietek/cannot-website/))
- [Least Fixed website](http://leastfixed.com/) ([Source](https://github.com/mietek/least-fixed-website/))
- [Miëtek Bak website](http://mietek.io/) ([Source](https://github.com/mietek/mietek-website/))


Usage
-----

Available as a [Bower](http://bower.io/) package.

```
$ bower install cannot
$ ln -s bower_components/cannot/Makefile .
$ make
```


### Dependencies

_cannot_ requires [GNU _make_](http://gnu.org/software/make/), [GNU _bash_](http://gnu.org/software/bash/), and:

- [_pandoc_](http://johnmacfarlane.net/pandoc/) for generating pages.
- [Sass](http://sass-lang.com/) and [_clean-css_](https://github.com/jakubpawlowicz/clean-css/) for processing stylesheets.
- [_webpack_](http://webpack.github.io/) for bundling scripts.
- [Advance<span class="small-caps">Comp</span>](http://advancemame.sourceforge.net/comp-readme.html) for recompressing archives.
- [ImageMagick](http://www.imagemagick.org/), [_jpegoptim_](https://github.com/tjko/jpegoptim/), and [OptiPNG](http://optipng.sourceforge.net/) for optimising images.
- [_fswatch_](https://github.com/emcrisostomo/fswatch/) and [BrowserSync](http://www.browsersync.io/) for automatic reloading.
- [_ease-scroll_](https://github.com/mietek/ease-scroll/) for smooth scrolling.
- [_git_](http://git-scm.com/) for publishing.

```
$ brew install advancecomp fswatch imagemagick jpegoptim node optipng pandoc
$ gem install sass
$ npm install -g bower browser-sync clean-css webpack
```

#### Non-free dependencies

- [Sketch](http://bohemiancoding.com/sketch/) for rebuilding images.
- [Icon Slate](http://www.kodlian.com/apps/icon-slate/) for rebuilding favicons.


### Bugs

Please report any problems with _cannot_ on the [issue tracker](https://github.com/mietek/cannot/issues/).

There is a [separate issue tracker](https://github.com/mietek/cannot-website/issues/) for problems with the documentation.


About
-----

My name is [Miëtek Bak](http://mietek.io/).  I make software, and _cannot_ is one of [my projects](http://mietek.io/projects/).

This work is published under the [MIT X11 license](http://cannot.mietek.io/license/), and supported by my company, [Least Fixed](http://leastfixed.com/).

Like my work?  I am available for consulting on software projects.  Say [hello](http://mietek.io/), or follow [@mietek](http://twitter.com/mietek).
