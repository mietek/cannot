# cannot
# ======
#
# Execute in parallel using the following flags:
#
#     export MAKEFLAGS=--no-builtin-rules --no-builtin-variables --warn-undefined-variables -j
#
# Dependencies are expected to be available as Bower components.  You need to run `bower install` yourself, as you may prefer to use `bower link`.
#
# The file system watching facility will not pick up the contents of newly symlinked directories without being turned off and on again, as `fswatch` does not automatically follow symlinks.


project-name  := $(notdir $(CURDIR))
canonical-url := $(shell cat page-metadata/canonical-url.txt)
s3-bucket     := $(patsubst https://%/,%,$(canonical-url))

SHELL := /usr/bin/env bash

.PHONY : all build clean dev watch pub push open
all    : dev-watch
build  : dev-build pub-build
clean  : unwatch ; rm -rf out
dev    : dev-watch
watch  : dev-watch
pub    : pub-push
push   : pub-push
open   : ; open $(canonical-url)

define cannot-macro
  .PHONY        : $(mode)-build
  $(mode)-build : $(mode)-pages $(mode)-scripts $(mode)-stylesheets $(mode)-fonts $(mode)-images $(mode)-iconsheet
  $(mode)-clean : unwatch ; rm -rf out/$(mode)

  out/$(mode) out/$(mode)/_fonts out/$(mode)/_images out/tmp/$(mode) : ; [ -d $$@ ] || mkdir -p $$@
endef
$(foreach mode,dev pub,$(eval $(cannot-macro)))

.DELETE_ON_ERROR :


# Utilities
# ---------

find-files = $(shell find -L $(1) -type f -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)
find-dirs  = $(shell find -L $(1) -type d -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)

extract-resources = grep -Eo 'url\($(1)/[^)]+\)' $< | sed -E 's,^.*/(.*)\).*$$,\1,' | sort -u >$@ || touch $@
extract-comments  = grep -Eo '/\* $(1): .* \*/' $< | sed -E 's/^.*: (.*) .*$$/\1/' | sort -u >$@ || touch $@


# Publishing
# ----------

define pub-sync-zip
  s3cmd sync out/pub/ s3://$(s3-bucket) --acl-public --cf-invalidate --no-preserve --add-header='Content-Encoding:gzip' --exclude='*' --include='*.gz'
endef

define pub-sync-all
  s3cmd sync out/pub/ s3://$(s3-bucket) --acl-public --cf-invalidate --no-preserve --delete-removed --exclude='*.git*'
endef

.PHONY : pub-push
pub-push : unwatch
	git push origin master
	rm -rf out/pub
	$(MAKE) pub-build
	$(pub-sync-zip)
	$(pub-sync-all)


# Watching
# --------

vpath %.js config bower_components/cannot/config

fswatch-roots := $(patsubst %,'%',$(realpath . $(shell find . -type l)))

fswatch-off     := pgrep -f 'fswatch.* --format-time pgrep/$(project-name)' | xargs kill
browsersync-off := pgrep -f 'browser-sync.* --files pgrep/$(project-name)' | xargs kill

.PHONY : unwatch
unwatch :
	$(fswatch-off)
	$(browsersync-off)

define watch-macro
  define $(mode)-watch
    $(fswatch-off)
    $(browsersync-off)
    fswatch --exclude='.*/out/.*' --one-per-batch --recursive $(fswatch-roots) --format-time pgrep/$(project-name) | xargs -n1 -I{} '$(MAKE)' $(mode)-build &
    ( while ps -p $$$${PPID} >/dev/null ; do sleep 1 ; done ; $(fswatch-off) ; $(browsersync-off) ) &
    browser-sync start --no-online --files 'out/$(mode)/**/*' --server 'out/$(mode)' --config=$$(filter %/browsersync.js,$$^) --files pgrep/$(project-name)
  endef

  .PHONY        : $(mode)-watch
  $(mode)-watch : $(mode)-build browsersync.js ; $$($(mode)-watch)
endef
$(foreach mode,dev pub,$(eval $(watch-macro)))


# Optimization
# ------------

dev-optimize-zip := true
define pub-optimize-zip
  advdef --iter 100 --shrink-insane --quiet -z $@
endef

dev-copy-optimized-css = cp $< $@
define pub-copy-optimized-css
  cleancss --s0 --skip-rebase $< >$@
endef

define dev-copy-optimized-jpg
  jpegoptim --force --all-normal -m80 --strip-all --quiet --stdout $< >$@
endef
pub-copy-optimized-jpg = $(dev-copy-optimized-jpg)

dev-optimize-png := true
define pub-optimize-png
  optipng -clobber -o6 -strip all -quiet $@ && $(pub-optimize-zip)
endef

define optimize-macro
  define $(mode)-create-zip
    gzip --fast --force --keep --no-name --to-stdout $$< >$$@ && $$($(mode)-optimize-zip)
  endef

  define $(mode)-copy-optimized-png
    cp $$< $$@ && $$($(mode)-optimize-png)
  endef

  out/$(mode)/%.gz : out/$(mode)/% | out/$(mode) ; $$($(mode)-create-zip)
endef
$(foreach mode,dev pub,$(eval $(optimize-macro)))


# Pages
# -----

vpath %.md   error-pages    bower_components/cannot/error-pages
vpath %.md   pages          bower_components/cannot/pages
vpath %.txt  page-metadata  bower_components/cannot/page-metadata
vpath %.html page-includes  bower_components/cannot/page-includes
vpath %.html page-templates bower_components/cannot/page-templates

page-template := main.html
page-includes := menu-items.html head.html header.html footer.html
page-metadata := $(wildcard page-metadata/*.txt)
gzip-suffix   := $(if $(filter no-gzip,$(shell cat page-metadata/no-gzip.txt 2>/dev/null)),,.gz)
std-errors    := 400 403 404 405 414 416 500 501 502 503 504
std-pages     := index.md error.md license/index.md $(patsubst %,_errors/%.md,$(std-errors))
pages         := $(sort $(std-pages) $(subst pages/,,$(call find-files,pages,*.md)))

define pages-macro
  $(mode)-pages := $(patsubst %.md,out/$(mode)/%.html,$(pages))

  define $(mode)-compile-md
    [ -d $$(@D) ] || mkdir -p $$(@D)
    pandoc \
      --from=markdown+auto_identifiers+header_attributes --to=html5 --section-divs --standalone \
      --metadata=$(mode):$(mode) \
      --metadata=project-name:$(project-name) \
      --metadata=path:$$(subst index.html,,$$(patsubst out/$(mode)/%,%,$$@)) \
      $$(foreach metadatum,$$(filter %.txt,$$^),--metadata=$$(patsubst %.txt,%,$$(notdir $$(metadatum))):"$$$$(< $$(metadatum) )") \
      $$(foreach include,$$(filter %.html,$$(filter-out %/$(page-template),$$^)),--metadata=$$(patsubst %.html,%,$$(notdir $$(include))):"$$$$(< $$(include) )") \
      --template=$$(filter %/$(page-template),$$^) \
      -o $$@ $$<
  endef

  define $(mode)-copy-md
    [ -d $$(@D) ] || mkdir -p $$(@D)
    cp $$< $$@
  endef

  out/tmp/$(mode)/%.html                 : %.md $(page-metadata) $(page-includes) $(page-template) | out/tmp/$(mode) ; $$($(mode)-compile-md)
  $$($(mode)-pages) : out/$(mode)/%.html : out/tmp/$(mode)/%.html                                  | out/$(mode)     ; $$($(mode)-copy-md)
endef
$(foreach mode,dev pub,$(eval $(pages-macro)))

.PHONY    : dev-pages pub-pages
dev-pages : $(dev-pages)
pub-pages : $(addsuffix $(gzip-suffix),$(pub-pages))


# Scripts
# -------

vpath %.js scripts bower_components/cannot/scripts

script-roots := scripts $(wildcard bower_components/*/scripts)
scripts      := main.js $(wildcard bower_components/*/index.js) $(call find-files,$(script-roots),*.js)

dev-webpack-flags := --debug --output-pathinfo
pub-webpack-flags := --optimize-minimize --optimize-occurence-order
webpack-config    := webpack.js

define scripts-macro
  define $(mode)-compile-js
    webpack --bail --define $(mode)=$(mode) $$($(mode)-webpack-flags) --config=$$(filter %/$(webpack-config),$$^) $$< $$@
  endef

  out/$(mode)/_scripts.js : $$(scripts) $(webpack-config) | out/$(mode) ; $$($(mode)-compile-js)
endef
$(foreach mode,dev pub,$(eval $(scripts-macro)))

.PHONY      : dev-scripts pub-scripts
dev-scripts : out/dev/_scripts.js
pub-scripts : $(addsuffix $(gzip-suffix),out/pub/_scripts.js)


# Stylesheets
# -----------

vpath %.sass stylesheets bower_components/cannot/stylesheets

stylesheet-main := main.sass
helper-roots    := stylesheets $(wildcard bower_components/*/stylesheets)
helpers         := $(call find-files,$(helper-roots),_*.sass _*.scss)

prefix-css = autoprefixer --browsers '> 1%, last 2 versions, Firefox ESR' --output $@ $<

define stylesheets-macro
  $(mode)-helper-roots := out/tmp/$(mode) $(helper-roots)
  $(mode)-helpers      := out/tmp/$(mode)/_iconsheet.scss $(helpers)

  define $(mode)-compile-sass
    sass --line-numbers --sourcemap=none --style expanded --cache-location out/tmp/$(mode)/.sass-cache $$(addprefix --load-path ,$$($(mode)-helper-roots)) $$< $$@
  endef

  out/tmp/$(mode)/stylesheets.css     : $(stylesheet-main) $$($(mode)-helpers)            ; $$($(mode)-compile-sass)
  out/tmp/$(mode)/stylesheets.pre.css : out/tmp/$(mode)/stylesheets.css                   ; $$(prefix-css)
  out/$(mode)/_stylesheets.css        : out/tmp/$(mode)/stylesheets.pre.css | out/$(mode) ; $$($(mode)-copy-optimized-css)
endef
$(foreach mode,dev pub,$(eval $(stylesheets-macro)))

.PHONY          : dev-stylesheets pub-stylesheets
dev-stylesheets : out/dev/_stylesheets.css
pub-stylesheets : $(addsuffix $(gzip-suffix),out/pub/_stylesheets.css)


# Fonts
# -----

font-roots := fonts $(wildcard bower_components/*/fonts)
font-dirs  := $(call find-dirs,$(font-roots),*)

vpath %.woff $(font-dirs)

out/tmp/dev/fonts.txt: out/tmp/dev/stylesheets.css | out/tmp/dev ; $(call extract-resources,_fonts)

define fonts-macro
  define $(mode)-echo-fonts
    echo '$(mode)-font-names := $$$$(shell cat out/tmp/dev/fonts.txt)' >$$@
    echo '$(mode)-fonts := $$$$(addprefix out/$(mode)/_fonts/,$$$$($(mode)-font-names))' >>$$@
    echo '$(mode)-fonts : $$$$($(mode)-fonts)' >>$$@
    echo '$$$$($(mode)-fonts) :' >>$$@
  endef

  .PHONY                   : $(mode)-fonts
  out/tmp/$(mode)/fonts.mk : out/tmp/dev/fonts.txt | out/tmp/$(mode) ; $$($(mode)-echo-fonts)
  -include out/tmp/$(mode)/fonts.mk

  out/$(mode)/_fonts/% : % | out/$(mode)/_fonts ; cp $$< $$@
endef
$(foreach mode,dev pub,$(eval $(fonts-macro)))


# Images
# ------

image-roots := images bower_components/cannot/images
image-dirs  := $(call find-dirs,$(image-roots),*)

vpath %.ico $(image-dirs)
vpath %.jpg $(image-dirs)
vpath %.png $(image-dirs)
vpath %.svg $(image-dirs)

out/tmp/dev/images.txt: out/tmp/dev/stylesheets.css | out/tmp/dev ; $(call extract-resources,_images)

define images-macro
  define $(mode)-echo-images
    echo '$(mode)-image-names := favicon-16.png favicon-32.png favicon-48.png $$$$(filter-out iconsheet%,$$$$(shell cat out/tmp/dev/images.txt))' >$$@
    echo '$(mode)-images := out/$(mode)/favicon.ico $$$$(addprefix out/$(mode)/_images/,$$$$($(mode)-image-names))' >>$$@
    echo '$(mode)-images : $(if $(filter dev,$(mode)),$$$$(dev-images),$$$$(pub-images) $$$$(addsuffix $(gzip-suffix),$$$$(filter %.svg,$$$$(pub-images))))' >>$$@
    echo '$$$$($(mode)-images) :' >>$$@
  endef

  .PHONY                    : $(mode)-images
  out/tmp/$(mode)/images.mk : out/tmp/dev/images.txt | out/tmp/$(mode) ; $$($(mode)-echo-images)
  -include out/tmp/$(mode)/images.mk

  out/$(mode)/%.ico         : %.ico | out/$(mode)         ; cp $$< $$@
  out/$(mode)/_images/%.jpg : %.jpg | out/$(mode)/_images ; $$($(mode)-copy-optimized-jpg)
  out/$(mode)/_images/%.png : %.png | out/$(mode)/_images ; $$($(mode)-copy-optimized-png)
  out/$(mode)/_images/%.svg : %.svg | out/$(mode)/_images ; cp $$< $$@
endef
$(foreach mode,dev pub,$(eval $(images-macro)))


# Iconsheets
# ----------

vpath %.txt image-metadata bower_components/cannot/image-metadata

out/tmp/dev/icon-shapes.txt : icon-shapes.txt | out/tmp/dev ; cp $< $@
out/tmp/dev/icon-colors.txt : icon-colors.txt | out/tmp/dev ; cp $< $@

out/tmp/pub/icon-shapes.txt : out/tmp/dev/stylesheets.css | out/tmp/pub ; $(call extract-comments,icon-shape)
out/tmp/pub/icon-colors.txt : out/tmp/dev/stylesheets.css | out/tmp/pub ; $(call extract-comments,icon-color)

define iconsheet-helper-macro
  define $(mode)-echo-iconsheet-helper
    echo '$$$$mode: $(mode);' >$$@
    echo '$$$$icon-shapes: ' >>$$@
    cat out/tmp/$(mode)/icon-shapes.txt >>$$@
    echo '; $$$$icon-colors: ' >>$$@
    cat out/tmp/$(mode)/icon-colors.txt >>$$@
    echo ';' >>$$@
  endef

  .PHONY                          : $(mode)-iconsheet
  out/tmp/$(mode)/icons.ready     : out/tmp/$(mode)/icon-shapes.txt out/tmp/$(mode)/icon-colors.txt ; touch $$@
  out/tmp/$(mode)/_iconsheet.scss : out/tmp/$(mode)/icons.ready                                     ; $$($(mode)-echo-iconsheet-helper)
endef
$(foreach mode,dev pub,$(eval $(iconsheet-helper-macro)))

define compile-icon-column
  convert $^ -append $@
endef

define iconsheet-macro
  define $(mode)-compile-iconsheet
    convert $$^ +append $$@ && $$($(mode)-optimize-png)
  endef

  define $(mode)-echo-iconsheet$($(scale))
    echo '$(mode)-icon-shapes$($(scale)) := $$$$(shell cat out/tmp/$(mode)/icon-shapes.txt)' >$$@
    echo '$(mode)-icon-colors$($(scale)) := $$$$(shell cat out/tmp/$(mode)/icon-colors.txt)' >>$$@
    echo '$(mode)-icon-columns$($(scale)) := $$$$(foreach shape,$$$$($(mode)-icon-shapes$($(scale))),out/tmp/$(mode)/icon-column-$$$$(shape)$$($(scale)).png)' >>$$@
    echo '$(mode)-icon-column-cells$($(scale)) := $$$$(addsuffix $($(scale)).png,$$$$(addprefix icon-%-,$$$$($(mode)-icon-colors$($(scale)))))' >>$$@
    echo '$$$$($(mode)-icon-columns$($(scale))) : out/tmp/$(mode)/icon-column-%$($(scale)).png : $$$$($(mode)-icon-column-cells$($(scale))) | out/tmp/$(mode) ; $$$$(compile-icon-column)' >>$$@
    echo 'out/$(mode)/_images/iconsheet$($(scale)).png : $$$$($(mode)-icon-columns$($(scale))) | out/$(mode)/_images ; $$$$($(mode)-compile-iconsheet)' >>$$@
  endef

  $(mode)-iconsheet                        : out/$(mode)/_images/iconsheet$$($(scale)).png
  out/tmp/$(mode)/iconsheet$$($(scale)).mk : out/tmp/$(mode)/icons.ready ; $$($(mode)-echo-iconsheet$$($(scale)))
  -include out/tmp/$(mode)/iconsheet$$($(scale)).mk
endef
scale@1x :=
scale@2x := @2x
$(foreach mode,dev pub,$(foreach scale,scale@1x scale@2x,$(eval $(iconsheet-macro))))
