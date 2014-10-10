[cannot](http://mietek.github.io/cannot/)
=========================================

Microframework for building websites.

Uses [ease-scroll](https://github.com/mietek/ease-scroll/) for smooth scrolling.

Used in:

- [My website](https://github.com/mietek/mietek-website/) ([Live](http://mietek.github.io/))
- [Website for Least Fixed](https://github.com/mietek/least-fixed-website/) ([Live](http://mietek.github.io/least-fixed-website/))
- [Website for bashmenot](https://github.com/mietek/bashmenot-website/) ([Live](http://mietek.github.io/bashmenot-website/))
- [Website for Halcyon](https://github.com/mietek/halcyon-website/) ([Live](http://mietek.github.io/halcyon-website/))
- [Website for Haskell on Heroku](https://github.com/mietek/haskell-on-heroku-website/) ([Live](http://mietek.github.io/haskell-on-heroku-website/))
- [Website for Motoworks Cambridge](https://github.com/mietek/motoworks-website/) ([Live](http://mietek.github.io/motoworks-website/))


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

Requires [GNU make](http://gnu.org/software/make/).

Generating pages requires [Pandoc](http://johnmacfarlane.net/pandoc/).  Processing stylesheets requires [Sass](http://sass-lang.com/) and [CleanCSS](https://github.com/jakubpawlowicz/clean-css/).  Bundling scripts requires [Webpack](http://webpack.github.io/).

Recompressing archives requires [AdvanceComp](http://advancemame.sourceforge.net/comp-readme.html).  Optimising images also requires [ImageMagick](http://www.imagemagick.org/), [JPEGOptim](https://github.com/tjko/jpegoptim/), and [OptiPNG](http://optipng.sourceforge.net/).

Live reloading requires [FSWatch](https://github.com/emcrisostomo/fswatch/) and [BrowserSync](http://www.browsersync.io/).

```
$ brew install advancecomp fswatch imagemagick jpegoptim node optipng pandoc
$ gem install sass
$ npm install -g bower browser-sync clean-css webpack
```

Rebuilding the source images requires [Sketch](http://bohemiancoding.com/sketch/) and [Icon Slate](http://www.kodlian.com/apps/icon-slate/).


License
-------

Made by [Miëtek Bak](http://mietek.io/).  Published under the [MIT X11 license](https://github.com/mietek/license/blob/master/LICENSE.md).
