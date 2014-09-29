# ---------------------------------------------------------------------------
# Cannot
# ---------------------------------------------------------------------------

.DELETE_ON_ERROR :

.PHONY : all build clean dev watch
all    : dev-watch
build  : dev-build pub-build
clean  : ; rm -rf out
dev    : dev-watch
watch  : dev-watch

define cannot-macro
  .PHONY        : $(mode)-build $(mode)-clean
  $(mode)-build : $(mode)-pages $(mode)-scripts $(mode)-stylesheets $(mode)-fonts $(mode)-images $(mode)-iconsheet
  $(mode)-clean : ; rm -rf out/$(mode)

  out/$(mode) out/$(mode)/_fonts out/$(mode)/_images out/tmp/$(mode) : ; [ -d $$@ ] || mkdir -p $$@
endef
$(foreach mode,dev pub,$(eval $(cannot-macro)))


# ---------------------------------------------------------------------------
# Watching
# ---------------------------------------------------------------------------

fswatch-roots := $(patsubst %,'%',$(realpath . $(shell find . -type l)))

define watch-macro
  # NOTE: This will not pick up new symlinks without restarting
  $(mode)-start-watch      := fswatch --exclude='$(CURDIR)/out' --one-per-batch --recursive $(fswatch-roots) | xargs -n1 -I{} '$(MAKE)' $(mode)-build & echo $$$$! >out/tmp/$(mode)/fswatch.pid
  $(mode)-stop-watch       := [ -f out/tmp/$(mode)/fswatch.pid ] && kill `cat out/tmp/$(mode)/fswatch.pid` 2>/dev/null ; rm -f out/tmp/$(mode)/fswatch.pid
  $(mode)-delay-stop-watch := ( while ps -p $$$${PPID} >/dev/null ; do sleep 1 ; done ; $$($(mode)-stop-watch) ) &
  $(mode)-start-sync       := browser-sync start --no-online --files 'out/$(mode)/**/*' --server out/$(mode)

  define $(mode)-watch
    $$($(mode)-stop-watch)
    $$($(mode)-start-watch)
    $$($(mode)-delay-stop-watch)
    $$($(mode)-start-sync)
  endef

  .PHONY        : $(mode)-watch
  $(mode)-watch : $(mode)-build ; $$($(mode)-watch)
endef
$(foreach mode,dev pub,$(eval $(watch-macro)))


# ---------------------------------------------------------------------------
# Optimization
# ---------------------------------------------------------------------------

dev-advdef-flags := --iter 1
pub-advdef-flags := --iter 100

dev-copy-optimized-jpg = cp $< $@
pub-copy-optimized-jpg = jpegoptim --force -m90 --strip-all --quiet --stdout $< >$@

dev-copy-optimized-css = cp $< $@
pub-copy-optimized-css = cleancss --s0 --skip-rebase $< >$@

define optimize-macro
  $(mode)-optimize-zip = advdef $($(mode)-advdef-flags) --shrink-insane --quiet -z $$@

  define $(mode)-create-zip
    gzip --fast --force --keep --no-name --to-stdout $$< >$$@
    $$($(mode)-optimize-zip)
  endef

  define $(mode)-optimize-png
    optipng -clobber -o6 -strip all -quiet $$@
    $$($(mode)-optimize-zip)
  endef

  define $(mode)-copy-optimized-png
    cp $$< $$@
    $$($(mode)-optimize-png)
  endef

  out/$(mode)/%.gz : out/$(mode)/% | out/$(mode) ; $$($(mode)-create-zip)
endef
$(foreach mode,dev pub,$(eval $(optimize-macro)))


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

find-files = $(shell find -L $(1) -type f -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)

vpath %.md   pages          bower_components/cannot/pages
vpath %.txt  page-metadata  bower_components/cannot/page-metadata
vpath %.html page-includes  bower_components/cannot/page-includes
vpath %.html page-templates bower_components/cannot/page-templates

page-template := main.html
page-includes := menu-items.html head-extra.html header-extra.html footer-extra.html
page-metadata := $(wildcard page-metadata/*.txt)
std-pages     := index.md error.md license/index.md
pages         := $(sort $(std-pages) $(subst pages/,,$(call find-files,pages,*.md)))

define pages-macro
  $(mode)-pages := $(patsubst %.md,out/$(mode)/%.html,$(pages))

  define $(mode)-compile-md
    [ -d $$(@D) ] || mkdir -p $$(@D)
    pandoc \
      --from=markdown+auto_identifiers+header_attributes --to=html5 --section-divs --standalone \
      --metadata=$(mode):$(mode) \
      --metadata=project-name:$(notdir $(CURDIR)) \
      --metadata=path:$(subst index.html,,$(patsubst out/$(mode)/%,%,$$@)) \
      $$(foreach metadatum,$$(filter %.txt,$$^),--metadata=$$(patsubst %.txt,%,$$(notdir $$(metadatum))):"`cat $$(metadatum)`") \
      $$(foreach include,$$(filter %.html,$$(filter-out %/$(page-template),$$^)),--metadata=$$(patsubst %.html,%,$$(notdir $$(include))):"`cat $$(include)`") \
      --template=$$(filter %/$(page-template),$$^) \
      -o $$@ $$<
  endef

  .PHONY            : $(mode)-pages
  $(mode)-pages     : $$($(mode)-pages)
  $$($(mode)-pages) : out/$(mode)/%.html : %.md $(page-metadata) $(page-includes) $(page-template) | out/$(mode) ; $$($(mode)-compile-md)
endef
$(foreach mode,dev pub,$(eval $(pages-macro)))


# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------

vpath %.js scripts bower_components/cannot/scripts

scripts := main.js $(wildcard bower_components/*/index.js)

dev-webpack-flags := --debug --output-pathinfo
pub-webpack-flags := --optimize-minimize --optimize-occurence-order
webpack-config    := webpack.js

define scripts-macro
  $(mode)-scripts := out/$(mode)/_scripts.js

  define $(mode)-compile-js
    webpack --bail --define $(mode)=$(mode) $$($(mode)-webpack-flags) --config=$$(filter %/$(webpack-config),$$^) $$< $$@
  endef

  .PHONY              : $(mode)-scripts
  $(mode)-scripts     : $$($(mode)-scripts)
  $$($(mode)-scripts) : $$(scripts) $(webpack-config) | out/$(mode) ; $$($(mode)-compile-js)
endef
$(foreach mode,dev pub,$(eval $(scripts-macro)))


# ---------------------------------------------------------------------------
# Stylesheets
# ---------------------------------------------------------------------------

vpath %.sass stylesheets bower_components/cannot/stylesheets

stylesheet-main := main.sass
helper-roots    := stylesheets $(wildcard bower_components/*/stylesheets)
helpers         := $(call find-files,$(helper-roots),_*.sass _*.scss)

prefix-css = autoprefixer --browsers '> 1%, last 2 versions, Firefox ESR' --output $@ $<

define stylesheets-macro
  $(mode)-helper-roots := out/tmp/$(mode) $(helper-roots)
  $(mode)-helpers      := out/tmp/$(mode)/_iconsheet.scss $(helpers)
  $(mode)-stylesheets  := out/$(mode)/_stylesheets.css out/$(mode)/_stylesheets.css.gz

  define $(mode)-compile-sass
    sass --line-numbers --sourcemap=none --style expanded --cache-location out/tmp/$(mode)/.sass-cache $$(addprefix --load-path ,$$($(mode)-helper-roots)) $$< $$@
  endef

  .PHONY                              : $(mode)-stylesheets
  $(mode)-stylesheets                 : $$($(mode)-stylesheets)
  out/tmp/$(mode)/stylesheets.css     : $(stylesheet-main) $$($(mode)-helpers)            ; $$($(mode)-compile-sass)
  out/tmp/$(mode)/stylesheets.pre.css : out/tmp/$(mode)/stylesheets.css                   ; $$(prefix-css)
  out/$(mode)/_stylesheets.css        : out/tmp/$(mode)/stylesheets.pre.css | out/$(mode) ; $$($(mode)-copy-optimized-css)
endef
$(foreach mode,dev pub,$(eval $(stylesheets-macro)))


# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------

find-dirs         = $(shell find -L $(1) -type d -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)
extract-resources = grep -Eo 'url\($(1)/[^)]+\)' $< | sed -E 's,^.*/(.*)\).*$$,\1,' | sort -u >$@ || touch $@

font-roots := fonts $(wildcard bower_components/*/fonts)
font-dirs  := $(call find-dirs,$(font-roots),*)

vpath %.woff $(font-dirs)

out/tmp/dev/fonts.txt: out/tmp/dev/stylesheets.css | out/tmp/dev ; $(call extract-resources,_fonts)

fonts = $(shell cat out/tmp/dev/fonts.txt)

define fonts-macro
  $(mode)-fonts = $$(addprefix out/$(mode)/_fonts/,$$(fonts))

  .PHONY                   : $(mode)-fonts
  out/tmp/$(mode)/fonts.mk : out/tmp/dev/fonts.txt | out/tmp/$(mode) ; echo '$(mode)-fonts: $$($(mode)-fonts)' >$$@
  -include out/tmp/$(mode)/fonts.mk

  out/$(mode)/_fonts/% : % | out/$(mode)/_fonts ; cp $$< $$@
endef
$(foreach mode,dev pub,$(eval $(fonts-macro)))


# ---------------------------------------------------------------------------
# Images
# ---------------------------------------------------------------------------

image-roots := images bower_components/cannot/images
image-dirs  := $(call find-dirs,$(image-roots),*)
std-images  := favicon-16.png favicon-32.png favicon-48.png

vpath %.ico $(image-dirs)
vpath %.jpg $(image-dirs)
vpath %.png $(image-dirs)
vpath %.svg $(image-dirs)

out/tmp/dev/images.txt: out/tmp/dev/stylesheets.css | out/tmp/dev ; $(call extract-resources,_images)

images = $(std-images) $(filter-out iconsheet%,$(shell cat out/tmp/dev/images.txt))

define images-macro
  $(mode)-images = out/$(mode)/favicon.ico $$(addprefix out/$(mode)/_images/,$$(images) $$(addsuffix .gz,$$(filter %.svg,$$(images))))

  .PHONY                    : $(mode)-images
  out/tmp/$(mode)/images.mk : out/tmp/dev/images.txt | out/tmp/$(mode) ; echo '$(mode)-images: $$($(mode)-images)' >$$@
  -include out/tmp/$(mode)/images.mk

  out/$(mode)/%.ico         : %.ico | out/$(mode)         ; cp $$< $$@
  out/$(mode)/_images/%     : %     | out/$(mode)/_images ; cp $$< $$@
  out/$(mode)/_images/%.jpg : %.jpg | out/$(mode)/_images ; $$($(mode)-copy-optimized-jpg)
  out/$(mode)/_images/%.png : %.png | out/$(mode)/_images ; $$($(mode)-copy-optimized-png)
endef
$(foreach mode,dev pub,$(eval $(images-macro)))


# ---------------------------------------------------------------------------
# Iconsheets
# ---------------------------------------------------------------------------

extract-comments = grep -Eo '/\* $(1): .* \*/' $< | sed -E 's/^.*: (.*) .*$$/\1/' | sort -u >$@ || touch $@

vpath %.txt image-metadata bower_components/cannot/image-metadata

out/tmp/dev/icon-shapes.txt : icon-shapes.txt | out/tmp/dev ; cp $< $@
out/tmp/dev/icon-colors.txt : icon-colors.txt | out/tmp/dev ; cp $< $@

out/tmp/pub/icon-shapes.txt : out/tmp/dev/stylesheets.css | out/tmp/pub ; $(call extract-comments,icon-shape)
out/tmp/pub/icon-colors.txt : out/tmp/dev/stylesheets.css | out/tmp/pub ; $(call extract-comments,icon-color)

define iconsheet-helper-macro
  $(mode)-icon-shapes = $$(shell cat out/tmp/$(mode)/icon-shapes.txt)
  $(mode)-icon-colors = $$(shell cat out/tmp/$(mode)/icon-colors.txt)

  define $(mode)-write-iconsheet-helper
    echo '$$$$icon-shapes: ' >$$@
    cat out/tmp/$(mode)/icon-shapes.txt >>$$@
    echo '; $$$$icon-colors: ' >>$$@
    cat out/tmp/$(mode)/icon-colors.txt >>$$@
    echo ';' >>$$@
  endef

  .PHONY                          : $(mode)-iconsheet
  out/tmp/$(mode)/icons.ready     : out/tmp/$(mode)/icon-shapes.txt out/tmp/$(mode)/icon-colors.txt ; touch $$@
  out/tmp/$(mode)/_iconsheet.scss : out/tmp/$(mode)/icons.ready                                     ; $$($(mode)-write-iconsheet-helper)
endef
$(foreach mode,dev pub,$(eval $(iconsheet-helper-macro)))

scale@1x :=
scale@2x := @2x

define iconsheet-macro
  $(mode)-icon-cells$($(scale))   = $$(patsubst %,icon-$$$${shape}-%$($(scale)).png,$$($(mode)-icon-colors))
  $(mode)-icon-columns$($(scale)) = $$(foreach shape,$$($(mode)-icon-shapes),out/tmp/$(mode)/icon-column-$$(shape)$$($(scale)).png)

  define $(mode)-write-iconsheet$$($(scale))
    echo >$$@
    for shape in $$($(mode)-icon-shapes) ; do \
    echo "out/tmp/$(mode)/icon-column-$$$${shape}$$($(scale)).png : $$($(mode)-icon-cells$$($(scale))) | out/tmp/$(mode)" >>$$@ ; \
    echo '	convert $$$$^ -append $$$$@' >>$$@ ; \
    done
    echo 'out/$(mode)/_images/iconsheet$$($(scale)).png : $$($(mode)-icon-columns$$($(scale))) | out/$(mode)/_images' >>$$@ ; \
    echo '	convert $$$$^ +append $$$$@' >>$$@
    echo '	$$$$($(mode)-optimize-png)' >>$$@
  endef

  $(mode)-iconsheet                        : out/$(mode)/_images/iconsheet$$($(scale)).png
  out/tmp/$(mode)/iconsheet$$($(scale)).mk : out/tmp/$(mode)/icons.ready ; $$($(mode)-write-iconsheet$$($(scale)))
  -include out/tmp/$(mode)/iconsheet$$($(scale)).mk
endef
$(foreach mode,dev pub,$(foreach scale,scale@1x scale@2x,$(eval $(iconsheet-macro))))
