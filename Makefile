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

out out/tmp : ; mkdir -p $@

define cannot-macro
  .PHONY        : $(mode)-build $(mode)-clean
  $(mode)-build : $(mode)-pages $(mode)-scripts $(mode)-stylesheets $(mode)-iconsheet $(mode)-images $(mode)-fonts
  $(mode)-clean : ; rm -rf out/$(mode)

  out/$(mode) out/$(mode)/_images out/$(mode)/_fonts) out/tmp/$(mode) : ; mkdir -p $$@
endef
$(foreach mode,dev pub,$(eval $(cannot-macro)))


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

find-files = $(shell find -L $(1) -type f -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)
find-dirs  = $(shell find -L $(1) -type d -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)


# ---------------------------------------------------------------------------
# Watching
# ---------------------------------------------------------------------------

fswatch-roots := $(patsubst %,'%',$(realpath . $(shell find . -type l)))

define watch-macro
  # NOTE: This will not pick up new symlinks without restarting
  $(mode)-start-watch      := fswatch --exclude='$(CURDIR)/out' --one-per-batch --recursive $(fswatch-roots) | xargs -n1 -I{} '$(MAKE)' $(mode)-build & echo $$$$! >out/tmp/$(mode)/fswatch.pid
  $(mode)-stop-watch       := [ -f out/tmp/$(mode)/fswatch.pid ] && kill `cat out/tmp/$(mode)/fswatch.pid` 2>/dev/null; rm -f out/tmp/$(mode)/fswatch.pid
  $(mode)-delay-stop-watch := ( while ps -p $$$${PPID} >/dev/null; do sleep 1; done; $$($(mode)-stop-watch) ) &
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

dev-advdef-flags := --iter=1
pub-advdef-flags := --iter=100

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

  out/$(mode)/%.gz : out/$(mode)/% | out/$(mode) ; $$($(mode)-create-zip)
endef
$(foreach mode,dev pub,$(eval $(optimize-macro)))

optimize-jpg = jpegoptim -m90 --strip-all --quiet $@
optimize-css = cleancss --s0 --skip-rebase --output $@ $<
prefix-css   = autoprefixer --browsers '> 1%, last 2 versions, Firefox ESR' --output $@ $<


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

vpath %.md   pages          bower_components/cannot/pages
vpath %.txt  page-metadata  bower_components/cannot/page-metadata
vpath %.html page-includes  bower_components/cannot/page-includes
vpath %.html page-templates bower_components/cannot/page-templates

page-template := main.html
page-includes := menu-items.html head-extra.html header-extra.html footer-extra.html
page-metadata := $(wildcard page-metadata/*.txt)
pages         := $(sort index.md error.md license/index.md $(subst pages/,,$(call find-files,pages,*.md)))

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
# Iconsheet helper (dev)
# ---------------------------------------------------------------------------

vpath %.txt image-metadata bower_components/cannot/image-metadata

define write-iconsheet-helper
  echo '$$icon-shapes: ' >$@
  cat $(filter %/icon-shapes.txt,$^) >>$@
  echo ';' >>$@
  echo '$$icon-colors: ' >>$@
  cat $(filter %/icon-colors.txt,$^) >>$@
  echo ';' >>$@
endef


out/tmp/dev/_iconsheet.scss: icon-shapes.txt icon-colors.txt | out/tmp/dev
	$(write-iconsheet-helper)


# ---------------------------------------------------------------------------
# Stylesheets (dev)
# ---------------------------------------------------------------------------

vpath %.sass stylesheets bower_components/cannot/stylesheets

common-helper-roots := stylesheets $(wildcard bower_components/*/stylesheets)
common-helper-files := $(call find-files,$(common-helper-roots),_*.sass _*.scss)

helper-roots = out/tmp/$(1) $(common-helper-roots)
helper-files = out/tmp/$(1)/_iconsheet.scss $(common-helper-files)

define compile-sass
  sass \
    --line-numbers \
    --sourcemap=none \
    --style expanded \
    --cache-location out/tmp/$(1)/.sass-cache \
    $(addprefix --load-path ,$(helper-roots)) \
    $< \
    $@
endef


.PHONY: dev-stylesheets
dev-stylesheets: out/dev/_stylesheets.css

out/tmp/dev/stylesheets.css: main.sass $(call helper-files,dev)
	$(call compile-sass,dev)

out/dev/_stylesheets.css: out/tmp/dev/stylesheets.css | out/dev
	$(prefix-css)


# ---------------------------------------------------------------------------
# Iconsheet helper (pub)
# ---------------------------------------------------------------------------

extract-comments  = grep -Eo '/\* $(1): .* \*/' $< | sed -E 's/^.*: (.*) .*$$/\1/' | sort -u >$@ || touch $@
extract-resources = grep -Eo 'url\($(1)/[^)]+\)' $< | sed -E 's,^.*/(.*)\).*$$,\1,' | sort -u >$@ || touch $@

out/tmp/pub/icon-shapes.txt: out/tmp/dev/stylesheets.css | out/tmp/pub
	$(call extract-comments,icon-shape)

out/tmp/pub/icon-colors.txt: out/tmp/dev/stylesheets.css | out/tmp/pub
	$(call extract-comments,icon-color)

out/tmp/pub/_iconsheet.scss: out/tmp/pub/icon-shapes.txt out/tmp/pub/icon-colors.txt
	$(write-iconsheet-helper)


# ---------------------------------------------------------------------------
# Stylesheets (pub)
# ---------------------------------------------------------------------------

.PHONY: pub-stylesheets
pub-stylesheets: out/pub/_stylesheets.css.gz

out/tmp/pub/stylesheets.css: main.sass $(call helper-files,pub)
	$(call compile-sass,pub)

out/tmp/pub/stylesheets-prefixed.css: out/tmp/pub/stylesheets.css
	$(prefix-css)

out/pub/_stylesheets.css: out/tmp/pub/stylesheets-prefixed.css | out/pub
	$(optimize-css)


# ---------------------------------------------------------------------------
# Images
# ---------------------------------------------------------------------------

image-roots := images bower_components/cannot/images
image-dirs  := $(call find-dirs,$(image-roots),*)

vpath %.ico $(image-dirs)
vpath %.jpg $(image-dirs)
vpath %.png $(image-dirs)
vpath %.svg $(image-dirs)


out/tmp/image-names.txt: out/tmp/dev/stylesheets.css | out/tmp
	$(call extract-resources,_images)

image-names = favicon-16.png favicon-32.png favicon-48.png $(filter-out iconsheet%,$(shell cat out/tmp/image-names.txt))


define images
  $(mode)-images = out/$(mode)/favicon.ico $$(addprefix out/$(mode)/_images/,$$(image-names))

  .PHONY: $(mode)-images
  out/tmp/$(mode)/images.mk: out/tmp/image-names.txt; echo '$(mode)-images: $$($(mode)-images)' >$$@
  -include out/tmp/$(mode)/images.mk

  out/$(mode)/%.ico: %.ico | out/$(mode); cp $$< $$@
  out/$(mode)/_images/%: % | out/$(mode)/_images; cp $$< $$@
endef

$(foreach mode,dev pub,$(eval $(images)))


out/pub/_images/%.jpg: %.jpg | out/pub/_images
	cp $< $@
	$(optimize-jpg)

out/pub/_images/%.png: %.png | out/pub/_images
	cp $< $@
	$(pub-optimize-png)


# ---------------------------------------------------------------------------
# Iconsheet
# ---------------------------------------------------------------------------

icon-shapes = $(shell cat out/tmp/$(1)/icon-shapes.txt)
icon-colors = $(shell cat out/tmp/$(1)/icon-colors.txt)

icon-cell-files   = $(patsubst %,icon-$${shape}-%$(2).png,$(icon-colors))
icon-column-files = $(foreach shape,$(icon-shapes),out/tmp/$(1)/icon-column-$(shape)$(2).png)

define compile-icon-column
  convert $^ -append $@
endef

define compile-iconsheet
  convert $^ +append $@
  $($(1)-optimize-png)
endef

define write-icon-column-targets
  for shape in $(icon-shapes); do \
    echo "out/tmp/$(1)/icon-column-$${shape}$(2).png: $(call icon-cell-files,$(1),$(2)) | out/tmp/$(1)" >>$@; \
    echo '	$$(call compile-icon-column,$(1),$(2))' >>$@; \
  done
endef

define write-iconsheet-target
  echo 'out/$(1)/_images/iconsheet$(2).png: $(call icon-column-files,$(1),$(2)) | out/$(1)/_images' >>$@
  echo '	$$(call compile-iconsheet,$(1),$(2))' >>$@
endef


.PHONY: dev-iconsheet
dev-iconsheet: out/dev/_images/iconsheet.png out/dev/_images/iconsheet@2x.png

out/tmp/dev/%.txt: %.txt | out/tmp/dev
	cp $< $@

out/tmp/dev/iconsheet.mk: out/tmp/dev/icon-shapes.txt out/tmp/dev/icon-colors.txt
	echo >$@
	$(call write-icon-column-targets,dev,)
	$(call write-icon-column-targets,dev,@2x)
	$(call write-iconsheet-target,dev,)
	$(call write-iconsheet-target,dev,@2x)

-include out/tmp/dev/iconsheet.mk


.PHONY: pub-iconsheet
pub-iconsheet: out/pub/_images/iconsheet.png out/pub/_images/iconsheet@2x.png

out/tmp/pub/iconsheet.mk: out/tmp/pub/icon-shapes.txt out/tmp/pub/icon-colors.txt
	echo >$@
	$(call write-icon-column-targets,pub,)
	$(call write-icon-column-targets,pub,@2x)
	$(call write-iconsheet-target,pub,)
	$(call write-iconsheet-target,pub,@2x)

-include out/tmp/pub/iconsheet.mk


# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------

font-roots := fonts $(wildcard bower_components/*/fonts)
font-dirs  := $(call find-dirs,$(font-roots),*)

vpath %.woff $(font-dirs)


out/tmp/font-names.txt: out/tmp/dev/stylesheets.css
	$(call extract-resources,_fonts)

font-names = $(shell cat out/tmp/font-names.txt)


define fonts
  $(mode)-fonts = $$(addprefix out/$(mode)/_fonts/,$$(font-names))

  out/tmp/$(mode)/fonts.mk: out/tmp/font-names.txt; echo '$(mode)-fonts: $$($(mode)-fonts)' >$$@

  .PHONY: $(mode)-fonts
  -include out/tmp/$(mode)/fonts.mk

  out/$(mode)/_fonts/%.woff: %.woff | out/$(mode)/_fonts; cp $$< $$@
endef

$(foreach mode,dev pub,$(eval $(fonts)))
