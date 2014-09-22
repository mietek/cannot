.PHONY: all build dev pub clean

all: build

build: dev-build pub-build

dev: dev-watch

pub: pub-watch

clean:
	rm -rf out

.DELETE_ON_ERROR:


# ---------------------------------------------------------------------------
# Goals
# ---------------------------------------------------------------------------

# NOTE: This will not pick up new symlinks without restarting
start-watching = \
  fswatch \
    --one-per-batch \
    --recursive \
    --exclude='$(CURDIR)/out' \
    $(patsubst %,'%',$(realpath . $(shell find . -type l))) \
  | xargs -n1 -I{} \
    '$(MAKE)' $(1)-build \
  & echo $$! \
    >out/tmp/fswatch.pid

stop-watching = \
  kill `cat out/tmp/fswatch.pid` \
    2>/dev/null

remember-to-stop-watching = \
  ( \
    while ps -p $${PPID} >/dev/null; do \
      sleep 1; \
    done; \
    $(call stop-watching) \
  ) &

start-synchronizing = \
  browser-sync start \
    --no-online \
    --files 'out/$(1)/**/*' \
    --server out/$(1)


.PHONY: dev-build dev-watch dev-clean

dev-build: dev-pages dev-scripts dev-stylesheets dev-images dev-fonts

dev-watch: dev-build
	-$(call stop-watching)
	$(call start-watching,dev)
	$(call remember-to-stop-watching)
	$(call start-synchronizing,dev)

dev-clean:
	rm -rf out/dev


.PHONY: pub-build pub-watch pub-clean

pub-build: pub-pages pub-scripts pub-stylesheets pub-images pub-fonts

pub-watch: pub-build
	-$(call stop-watching)
	$(call start-watching,pub)
	$(call remember-to-stop-watching)
	$(call start-synchronizing,pub)

pub-clean:
	rm -rf out/pub


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

find-files = $(shell find -L $(1) -type f -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)
find-dirs  = $(shell find -L $(1) -type d -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)


%.gz: %
	gzip --fast --force --keep --no-name $<
	$(call optimize-zip)

out/dev out/dev/_fonts out/dev/_images out/pub out/pub/_fonts out/pub/_images out/tmp out/tmp/dev out/tmp/pub:
	mkdir -p $@


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

vpath %.md     pages     bower_components/cannot/pages
vpath %.html.t templates bower_components/cannot/templates

compile-md = \
  pandoc \
    --metadata=$(1):$(1) \
    --metadata=project-name:$(notdir $(CURDIR)) \
    $(foreach key,$(filter page-metadata/%,$^),$(addprefix --metadata=,$(notdir $(key)):$(shell cat $(key)))) \
    --from=markdown+auto_identifiers+header_attributes \
    --to=html5 \
    --smart \
    --standalone \
    --template=$(filter %/main.html.t,$^) \
    --include-before-body=$(filter %/header.html.t,$^) \
    --include-after-body=$(filter %/footer.html.t,$^) \
    --output $@ \
    $<

page-metadata = $(wildcard page-metadata/$(1)/*)
page-dirs     = $(patsubst %.md,out/$(1)/%,$(page-names))
pages         = out/$(1)/index.html out/$(1)/error.html $(patsubst %.md,out/$(1)/%/index.html,$(page-names))

page-files          := $(wildcard pages/*.md)
page-names          := license.md $(filter-out index.md error.md,$(notdir $(page-files)))
page-template-names := main.html.t header.html.t footer.html.t


dev-page-metadata := $(call page-metadata,dev)
dev-page-dirs     := $(call page-dirs,dev)
dev-pages         := $(call pages,dev)

.PHONY: dev-pages
dev-pages: $(dev-pages)

out/dev/%.html: %.md $(page-template-names) $(dev-page-metadata) | out/dev
	$(call compile-md,dev)

out/dev/%/index.html: %.md $(page-template-names) $(dev-page-metadata)
	[ -d $(@D) ] || mkdir -p $(@D)
	$(call compile-md,dev)


pub-page-metadata := $(call page-metadata,pub)
pub-page-dirs     := $(call page-dirs,pub)
pub-pages         := $(call pages,pub)

.PHONY: pub-pages
pub-pages: $(pub-pages)

out/pub/%.html: %.md $(page-template-names) $(pub-page-metadata) | out/pub
	$(call compile-md,pub)

out/pub/%/index.html: %.md $(page-template-names) $(pub-page-metadata)
	[ -d $(@D) ] || mkdir -p $(@D)
	$(call compile-md,pub)


# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------

vpath %.js scripts bower_components/cannot/scripts

compile-js = \
  webpack \
    --define $(1)=$(1) \
    $(2) \
    --bail \
    --config=$(filter %/webpack.js,$^) \
    $< \
    $@

script-files := main.js $(wildcard bower_components/*/index.js)


.PHONY: dev-scripts
dev-scripts: out/dev/_scripts.js

out/dev/_scripts.js: main.js $(script-files) webpack.js | out/dev
	$(call compile-js,dev,--debug --output-pathinfo)


.PHONY: pub-scripts
pub-scripts: out/pub/_scripts.js.gz

out/pub/_scripts.js: main.js $(script-files) webpack.js | out/pub
	$(call compile-js,pub,--optimize-minimize --optimize-occurence-order)


# ---------------------------------------------------------------------------
# Iconsheet helper (dev)
# ---------------------------------------------------------------------------

vpath %.txt images bower_components/cannot/images

generate-iconsheet-helper = \
  echo '$$icon-shapes: ' >$@ \
  && cat $(filter %/icon-shapes.txt,$^) >>$@ \
  && echo ';' >>$@ \
  && echo '$$icon-colors: ' >>$@ \
  && cat $(filter %/icon-colors.txt,$^) >>$@ \
  && echo ';' >>$@


out/tmp/dev/_iconsheet.scss: icon-shapes.txt icon-colors.txt | out/tmp/dev
	$(call generate-iconsheet-helper)


# ---------------------------------------------------------------------------
# Stylesheets (dev)
# ---------------------------------------------------------------------------

vpath %.sass stylesheets bower_components/cannot/stylesheets

common-helper-roots := stylesheets $(wildcard bower_components/*/stylesheets)
common-helper-files := $(call find-files,$(common-helper-roots),_*.sass _*.scss)

helper-roots = out/tmp/$(1) $(common-helper-roots)
helper-files = out/tmp/$(1)/_iconsheet.scss $(common-helper-files)

compile-sass = \
  sass \
    --line-numbers \
    --sourcemap=none \
    --style=expanded \
    --cache-location=out/tmp/$(1)/.sass-cache \
    $(addprefix --load-path=,$(call helper-roots,$(1))) \
    $< \
    $@

prefix-css = \
  autoprefixer \
    --browsers '> 1%, last 2 versions, Firefox ESR' \
    --output $(1) \
    $<


.PHONY: dev-stylesheets
dev-stylesheets: out/dev/_stylesheets.css

out/tmp/dev/stylesheets.css: main.sass $(call helper-files,dev)
	$(call compile-sass,dev)

out/dev/_stylesheets.css: out/tmp/dev/stylesheets.css | out/dev
	$(call prefix-css,$@)


# ---------------------------------------------------------------------------
# Iconsheet helper (pub)
# ---------------------------------------------------------------------------

extract-comments = \
  grep -Eo '/\* $(1): .* \*/' $< \
  | sed -E 's/^.*: (.*) .*$$/\1/' \
  | sort -u >$@


out/tmp/pub/icon-shapes.txt: out/tmp/dev/stylesheets.css | out/tmp/pub
	$(call extract-comments,icon-shape)

out/tmp/pub/icon-colors.txt: out/tmp/dev/stylesheets.css | out/tmp/pub
	$(call extract-comments,icon-color)

out/tmp/pub/_iconsheet.scss: out/tmp/pub/icon-shapes.txt out/tmp/pub/icon-colors.txt
	$(call generate-iconsheet-helper)


# ---------------------------------------------------------------------------
# Stylesheets (pub)
# ---------------------------------------------------------------------------

compress-css = \
  cleancss \
    --s0 \
    --output $@


.PHONY: pub-stylesheets
pub-stylesheets: out/pub/_stylesheets.css.gz

out/tmp/pub/stylesheets.css: main.sass $(call helper-files,pub)
	$(call compile-sass,pub)

out/pub/_stylesheets.css: out/tmp/pub/stylesheets.css | out/pub
	$(call prefix-css,-) | $(call compress-css)


# ---------------------------------------------------------------------------
# Images
# ---------------------------------------------------------------------------

image-roots := images bower_components/cannot/images
image-dirs  := $(call find-dirs,$(image-roots),*)

vpath %.ico $(image-dirs)
vpath %.jpg $(image-dirs)
vpath %.png $(image-dirs)
vpath %.svg $(image-dirs)

extract-resources = \
  grep -Eo 'url\($(1)/[^)]+\)' $< \
  | sed -E 's,^.*/(.*)\).*$$,\1,' \
  | sort -u >$@ \
  || touch $@

optimize-jpg = \
  jpegoptim \
    -m90 \
    --strip-all \
    --quiet \
    $@

optimize-png = \
  optipng \
    -clobber \
    -o6 \
    -strip all \
    -quiet \
    $@

optimize-zip = \
  advdef \
    --iter=100 \
    --shrink-insane \
    --quiet \
    -z \
    $@


out/tmp/image-names.txt: out/tmp/dev/stylesheets.css | out/tmp
	$(call extract-resources,_images)

image-names = favicon-16.png favicon-32.png favicon-48.png $(filter-out iconsheet%,$(shell cat out/tmp/image-names.txt))
dev-images  = out/dev/favicon.ico $(addprefix out/dev/_images/,$(image-names))
pub-images  = out/pub/favicon.ico $(addprefix out/pub/_images/,$(image-names) $(addsuffix .gz,$(filter %.svg,$(image-names))))


.PHONY: dev-images
.PHONY: pub-images
out/tmp/images.mk: out/tmp/image-names.txt
	echo 'dev-images: $(dev-images)' >$@
	echo 'pub-images: $(pub-images)' >>$@

-include out/tmp/images.mk


out/dev/%.ico: %.ico | out/dev
	cp $< $@

out/dev/_images/%: % | out/dev/_images
	cp $< $@


out/pub/%.ico: %.ico | out/pub
	cp $< $@

out/pub/_images/%.jpg: %.jpg | out/pub/_images
	cp $< $@
	$(call optimize-jpg)

out/pub/_images/%.png: %.png | out/pub/_images
	cp $< $@
	$(call optimize-png)
	$(call optimize-zip)

out/pub/_images/%: % | out/pub/_images
	cp $< $@


# ---------------------------------------------------------------------------
# Iconsheet images
# ---------------------------------------------------------------------------

icon-shapes = $(shell cat out/tmp/$(1)/icon-shapes.txt)
icon-colors = $(shell cat out/tmp/$(1)/icon-colors.txt)

icon-names = $(foreach shape,$(call icon-shapes,$(1)),$(patsubst %,icon-$(shape)-%$(2).png,$(call icon-colors,$(1))))

generate-iconsheet = \
  convert \
    $(foreach shape,$(call icon-shapes,$(1)),\( $(filter %/$(patsubst %,icon-$(shape)-%$(2).png,$(call icon-colors,$(1))),$^) -append \)) \
    +append $@


out/tmp/dev/%.txt: %.txt | out/tmp/dev
	cp $< $@

out/tmp/dev/iconsheet.mk: out/tmp/dev/icon-shapes.txt out/tmp/dev/icon-colors.txt
	echo 'out/dev/_images/iconsheet.png: $(call icon-names,dev,) | out/dev/_images' >$@
	echo 'out/dev/_images/iconsheet@2x.png: $(call icon-names,dev,@2x) | out/dev/_images' >>$@

-include out/tmp/dev/iconsheet.mk

out/dev/_images/iconsheet.png:
	$(call generate-iconsheet,dev,)

out/dev/_images/iconsheet@2x.png:
	$(call generate-iconsheet,dev,@2x)


out/tmp/pub/iconsheet.mk: out/tmp/pub/icon-shapes.txt out/tmp/pub/icon-colors.txt
	echo 'out/pub/_images/iconsheet.png: $(call icon-names,pub,) | out/pub/_images' >$@
	echo 'out/pub/_images/iconsheet@2x.png: $(call icon-names,pub,@2x) | out/pub/_images' >>$@

-include out/tmp/pub/iconsheet.mk

out/pub/_images/iconsheet.png:
	$(call generate-iconsheet,pub,)
	$(call optimize-png)
	$(call optimize-zip)

out/pub/_images/iconsheet@2x.png:
	$(call generate-iconsheet,pub,@2x)
	$(call optimize-png)
	$(call optimize-zip)


# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------

font-roots := fonts $(wildcard bower_components/*/fonts)
font-dirs  := $(call find-dirs,$(font-roots),*)

vpath %.woff $(font-dirs)


out/tmp/font-names.txt: out/tmp/dev/stylesheets.css
	$(call extract-resources,_fonts)

font-names = $(shell cat out/tmp/font-names.txt)
dev-fonts  = $(addprefix out/dev/_fonts/,$(font-names))
pub-fonts  = $(addprefix out/pub/_fonts/,$(font-names))


.PHONY: dev-fonts
.PHONY: pub-fonts
out/tmp/fonts.mk: out/tmp/font-names.txt
	echo 'dev-fonts: $(dev-fonts)' >$@
	echo 'pub-fonts: $(pub-fonts)' >>$@

-include out/tmp/fonts.mk


out/dev/_fonts/%.woff: %.woff | out/dev/_fonts
	cp $< $@

out/pub/_fonts/%.woff: %.woff | out/pub/_fonts
	cp $< $@
