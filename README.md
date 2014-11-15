[_cannot_](https://cannot.mietek.io/)
=====================================

_cannot_ is not a web framework.

> _“Those who do not understand Unix are condemned to reinvent it, poorly.”_  
> — [Henry Spencer](https://en.wikipedia.org/wiki/Henry_Spencer)


Usage
-----

```
$ bower install cannot
$ ln -s bower_components/cannot/Makefile .
$ make
```


### Examples

Live                                              | GitHub
--------------------------------------------------|---------
[Halcyon](https://halcyon.sh/)                    | [_halcyon-website_](https://github.com/mietek/halcyon-website/)
[Haskell on Heroku](https://haskellonheroku.com/) | [_haskell-on-heroku-website_](https://github.com/mietek/haskell-on-heroku-website/)
[Least Fixed](https://leastfixed.com/)            | [_least-fixed-website_](https://github.com/mietek/least-fixed-website/)
[Miëtek Bak](https://mietek.io/)                  | [_mietek-website_](https://github.com/mietek/mietek-website/)
[_bashmenot_](https://bashmenot.mietek.io/)       | [_bashmenot-website_](https://github.com/mietek/bashmenot-website/)
[_cannot_](https://cannot.mietek.io/)             | [_cannot-website_](https://github.com/mietek/cannot-website/)


### Documentation

- [Sample page](https://cannot.mietek.io/sample/)
- [Source code](https://github.com/mietek/cannot/)


### Dependencies

```
$ brew install advancecomp fswatch imagemagick jpegoptim node optipng pandoc
$ gem install sass
$ npm install -g browser-sync clean-css webpack
```

_cannot_ requires [GNU _make_](https://gnu.org/software/make/), [GNU _bash_](https://gnu.org/software/bash/), and:

- [Bower](http://bower.io/)—installation
- [_pandoc_](http://johnmacfarlane.net/pandoc/)—generating pages
- [Sass](http://sass-lang.com/) and [_clean-css_](https://github.com/jakubpawlowicz/clean-css/)—processing stylesheets
- [_webpack_](https://webpack.github.io/)—bundling scripts
- [Advance<span class="small-caps">Comp</span>](http://advancemame.sourceforge.net/comp-readme.html)—recompressing archives
- [ImageMagick](http://imagemagick.org/), [_jpegoptim_](https://github.com/tjko/jpegoptim/), and [OptiPNG](http://optipng.sourceforge.net/)—optimising images
- [Sketch](http://bohemiancoding.com/sketch/)—rebuilding images
- [Icon Slate](http://kodlian.com/apps/icon-slate/)—rebuilding favicons
- [_fswatch_](https://github.com/emcrisostomo/fswatch/) and [BrowserSync](http://browsersync.io/)—automatic reloading
- [_s3cmd_](http://s3tools.org/)—publishing to Amazon S3


### Support

Please report any problems with _cannot_ on the [issue tracker](https://github.com/mietek/cannot/issues/).  There is a [separate issue tracker](https://github.com/mietek/cannot-website/issues/) for problems with the documentation.


About
-----

My name is [Miëtek Bak](https://mietek.io/).  I make software, and _cannot_ is one of [my projects](https://mietek.io/projects/).

This work is published under the [MIT X11 license](https://cannot.mietek.io/license/), and supported by my company, [Least Fixed](https://leastfixed.com/).

Like my work?  I am available for consulting on software projects.  Say [hello](https://mietek.io/), or follow [@mietek](https://twitter.com/mietek).
