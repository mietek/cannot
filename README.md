cannot
======

Microframework for building websites.

Suitable for static sites and client-side apps.

Uses [ease-scroll](https://github.com/mietek/ease-scroll/) for smooth scrolling.


Usage
-----

Undergoing rapid development.  Not currently intended for public use.

Need a website?  Say hello@mietek.io

Examples:

- [My website](https://github.com/mietek/mietek-website/) ([Live](http://mietek.github.io/))
- [Website for Least Fixed](https://github.com/mietek/least-fixed-website/) ([Live](http://mietek.github.io/least-fixed-website/))
- [Website for Halcyon](https://github.com/mietek/halcyon-website/) ([Live](http://mietek.github.io/halcyon-website/))
- [Website for Haskell on Heroku](https://github.com/mietek/haskell-on-heroku-website/) ([Live](http://mietek.github.io/haskell-on-heroku-website/))
- [Website for Motoworks Cambridge](https://github.com/mietek/motoworks-website/) ([Live](http://mietek.github.io/motoworks-website/))


### Installation

Available as a [Bower](http://bower.io/) package.

```sh
bower install cannot
```


### Dependencies

Built with [GNU make](http://gnu.org/software/make/).

Pages generated with [Pandoc](http://johnmacfarlane.net/pandoc/).  Stylesheets processed with [Sass](http://sass-lang.com/) and [CleanCSS](https://github.com/jakubpawlowicz/clean-css/).  Scripts bundled with [Webpack](http://webpack.github.io/).

Images optimised with [ImageMagick](http://www.imagemagick.org/), [JPEGOptim](https://github.com/tjko/jpegoptim/), and [OptiPNG](http://optipng.sourceforge.net/).  Archives recompressed with [AdvanceComp](http://advancemame.sourceforge.net/comp-readme.html).

Live reloading with [FSWatch](https://github.com/emcrisostomo/fswatch/) and [BrowserSync](http://www.browsersync.io/).

```sh
brew install advancecomp fswatch imagemagick jpegoptim node optipng pandoc
gem install sass
npm install -g bower browser-sync clean-css webpack
```

Rebuilding the source images requires [Sketch](http://bohemiancoding.com/sketch/) and [Icon Slate](http://www.kodlian.com/apps/icon-slate/).


License
-------

[MIT X11](https://github.com/mietek/license/blob/master/LICENSE.md) © [Miëtek Bak](http://mietek.io/)
