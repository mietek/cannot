[_cannot_](http://cannot.mietek.io/)
====================================

_cannot_ is not a web framework.

> _“Those who do not understand Unix are condemned to reinvent it, poorly.”_  
> — [Henry Spencer](http://en.wikipedia.org/wiki/Henry_Spencer)


Examples
--------

- [This website](https://github.com/mietek/cannot-website/)
- [My website](https://github.com/mietek/mietek-website/)
- [_bashmenot_ website](https://github.com/mietek/bashmenot-website/)
- [Halcyon website](https://github.com/mietek/halcyon-website/)
- [Haskell on Heroku website](https://github.com/mietek/haskell-on-heroku-website/)
- [Least Fixed website](https://github.com/mietek/least-fixed-website/)


Usage
-----

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

_cannot_ requires [GNU _make_](http://gnu.org/software/make/) and [GNU _bash_](http://gnu.org/software/bash/).

- Generating pages requires [_pandoc_](http://johnmacfarlane.net/pandoc/).
- Processing stylesheets requires [Sass](http://sass-lang.com/) and [_clean-css_](https://github.com/jakubpawlowicz/clean-css/).
- Bundling scripts requires [_webpack_](http://webpack.github.io/).
- Recompressing archives requires [Advance<span class="small-caps">Comp</span>](http://advancemame.sourceforge.net/comp-readme.html).
- Optimising images requires [ImageMagick](http://www.imagemagick.org/), [_jpegoptim_](https://github.com/tjko/jpegoptim/), and [OptiPNG](http://optipng.sourceforge.net/).
- Automatic reloading requires [_fswatch_](https://github.com/emcrisostomo/fswatch/) and [BrowserSync](http://www.browsersync.io/).
- Smooth scrolling requires [_ease-scroll_](https://github.com/mietek/ease-scroll/).

```
$ brew install advancecomp fswatch imagemagick jpegoptim node optipng pandoc
$ gem install sass
$ npm install -g bower browser-sync clean-css webpack
```

- Rebuilding images requires [Sketch](http://bohemiancoding.com/sketch/).
- Rebuilding favicons requires [Icon Slate](http://www.kodlian.com/apps/icon-slate/).


### Bugs

Please report any problems with _cannot_ on the [issue tracker](https://github.com/mietek/cannot/issues/).

There is a [separate issue tracker](https://github.com/mietek/cannot-website/issues/) for problems with the documentation.


About
-----

My name is [Miëtek Bak](http://mietek.io/).  I make software, and _cannot_ is one of [my projects](http://mietek.io/projects/).

This work is published under the [MIT X11 license](http://cannot.mietek.io/license/), and supported by my company, [Least Fixed](http://leastfixed.com/).

Would you like to work with me?  Say [hello](http://mietek.io/).
