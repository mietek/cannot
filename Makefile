# ---------------------------------------------------------------------------
# Cannot
# ---------------------------------------------------------------------------

.PHONY: all
all: dev-watch

.PHONY: build
build: dev-build pub-build

.PHONY: dev
dev: dev-watch

.PHONY: watch
watch: dev-watch

.PHONY: pub
pub: pub-push

.PHONY: push
push: pub-push

.PHONY: open
open: pub-open

.PHONY: clean
clean:
	rm -rf out


.PHONY: dev-build
dev-build: dev-pages dev-scripts dev-stylesheets dev-images dev-iconsheet dev-fonts

.PHONY: dev-clean
dev-clean:
	rm -rf out/dev


.PHONY: pub-build
pub-build:
	$(MAKE) pub-build-1
	$(MAKE) pub-build-2

.PHONY: pub-build-1
pub-build-1: out/pub

.PHONY: pub-build-2
pub-build-2: pub-pages pub-scripts pub-stylesheets pub-images pub-iconsheet pub-fonts

.PHONY: pub-clean
pub-clean:
	rm -rf out/pub


.DELETE_ON_ERROR:


# ---------------------------------------------------------------------------
# Watching
# ---------------------------------------------------------------------------

fswatch-args := --exclude='$(CURDIR)/out' --one-per-batch --recursive
fswatch-roots := $(patsubst %,'%',$(realpath . $(shell find . -type l)))
fswatch := fswatch $(fswatch-args) $(fswatch-roots)

browsersync-args := --no-online
browsersync := browser-sync start $(browsersync-args)

define watch-template
  # NOTE: This will not pick up new symlinks without restarting
  define $(mode)-start-watch
    $(fswatch) | xargs -n1 -I{} '$(MAKE)' $(mode)-build & echo $$$$! >out/tmp/$(mode)/fswatch.pid
  endef

  define $(mode)-stop-watch
    kill `cat out/tmp/$(mode)/fswatch.pid 2>/dev/null` 2>/dev/null
  endef

  define $(mode)-delay-stop-watch
    ( while ps -p $$$${PPID} >/dev/null; do sleep 1; done; $$($(mode)-stop-watch) ) &
  endef

  define $(mode)-start-sync
    $(browsersync) --files 'out/$(mode)/**/*' --server out/$(mode)
  endef

  define $(mode)-watch
    -$$($(mode)-stop-watch)
    $$($(mode)-start-watch)
    $$($(mode)-delay-stop-watch)
    $$($(mode)-start-sync)
  endef

  .PHONY: $(mode)-watch
  $(mode)-watch: $(mode)-build; $$($(mode)-watch)
endef

$(foreach mode,dev pub,$(eval $(watch-template)))


# ---------------------------------------------------------------------------
# Publishing
# ---------------------------------------------------------------------------

pub-remote-name = $(shell git config --get cannot.pub.remote)
pub-remote-url  = $(shell git config --get remote.$(pub-remote-name).url)
pub-branch      = $(shell git config --get cannot.pub.branch)

define init-pub-branch
  git checkout --orphan gh-pages
  git config --add cannot.pub.remote origin
  git config --add cannot.pub.branch gh-pages
  git rm -rf .
  touch .nojekyll
  git add .nojekyll
  git commit -m "Initial commit"
  git push -u origin gh-pages
  git checkout master
  git branch -d gh-pages
endef

define clone-pub-branch
  git clone $(pub-remote-url) -b $(pub-branch) --single-branch out/pub
  find out/pub \
    | xargs touch -t 0101010101 -am
endef

define push-to-pub-branch
  [ -z "`git -C out/pub status --porcelain`" ] \
  || \
  ( \
    git -C out/pub add -A . \
    && git -C out/pub commit -m "Make" \
    && git -C out/pub push \
    && git fetch $(pub-remote-name) $(pub-branch) \
  )
endef


.PHONY: pub-init
pub-init:
	$(init-pub-branch)

out/pub:
	$(clone-pub-branch) || mkdir -p out/pub

.PHONY: pub-push
pub-push: pub-build
	$(push-to-pub-branch)

.PHONY: pub-open
pub-open:
	open `cat page-metadata/canonical-url.txt`


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

dev-advdef-flags := --iter=1
pub-advdef-flags := --iter=100

define optimize-zip
  advdef \
    $($(1)-advdef-flags) \
    --shrink-insane \
    --quiet \
    -z \
    $@
endef

define create-zip
  gzip \
    --fast \
    --force \
    --keep \
    --no-name \
    --to-stdout \
    $< \
    >$@
  $(optimize-zip)
endef

define optimize-png
  optipng \
    -clobber \
    -o6 \
    -strip all \
    -quiet \
    $@
  $(optimize-zip)
endef

define optimize-jpg
  jpegoptim \
    -m90 \
    --strip-all \
    --quiet \
    $@
endef

define optimize-css
  cleancss \
    --s0 \
    --skip-rebase \
    --output $@ \
    $<
endef

define prefix-css
  autoprefixer \
    --browsers '> 1%, last 2 versions, Firefox ESR' \
    --output $@ \
    $<
endef

define extract-comments
  grep -Eo '/\* $(1): .* \*/' $< \
  | sed -E 's/^.*: (.*) .*$$/\1/' \
  | sort -u >$@
endef

define extract-resources
  grep -Eo 'url\($(1)/[^)]+\)' $< \
  | sed -E 's,^.*/(.*)\).*$$,\1,' \
  | sort -u >$@ \
  || touch $@
endef


find-files = $(shell find -L $(1) -type f -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)
find-dirs  = $(shell find -L $(1) -type d -false $(foreach pattern,$(2),-or -name '$(pattern)') 2>/dev/null)


out/pub/%.gz: out/pub/%
	$(call create-zip,pub)

out/dev out/dev/_fonts out/dev/_images out/pub/_fonts out/pub/_images out/tmp out/tmp/dev out/tmp/pub:
	mkdir -p $@


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

vpath %.md   pages          bower_components/cannot/pages
vpath %.txt  page-metadata  bower_components/cannot/page-metadata
vpath %.html page-includes  bower_components/cannot/page-includes
vpath %.html page-templates bower_components/cannot/page-templates


page-metadata  := $(wildcard page-metadata/*.txt)

page-files     := $(call find-files,pages,*.md)
page-paths     := index.md error.md license/index.md $(subst pages/,,$(page-files))

page-structure := main.html menu-items.html head-extra.html header-extra.html footer-extra.html


define pages-template
  define $(mode)-compile-md
    [ -d $$(@D) ] || mkdir -p $$(@D)
    pandoc \
      --metadata=$(mode):$(mode) \
      --metadata=project-name:$(notdir $(CURDIR)) \
      --metadata=path:$(subst index.html,,$(patsubst out/$(mode)/%,%,$$@)) \
      --from=markdown+auto_identifiers+header_attributes \
      --to=html5 \
      --section-divs \
      --standalone \
      $$(foreach metadatum,$$(filter %.txt,$$^),--metadata=$$(patsubst %.txt,%,$$(notdir $$(metadatum))):"`cat $$(metadatum)`") \
      $$(foreach include,$$(filter %.html,$$(filter-out %/main.html,$$^)),--metadata=$$(patsubst %.html,%,$$(notdir $$(include))):"`cat $$(include)`") \
      --template=$$(filter %/main.html,$$^) \
      -o $$@ $$<
  endef

  $(mode)-pages := $(patsubst %.md,out/$(mode)/%.html,$(page-paths))

  .PHONY: $(mode)-pages
  $(mode)-pages: $$($(mode)-pages)

  out/$(mode)/%.html: %.md $(page-structure) $(page-metadata) | out/$(mode); $$($(mode)-compile-md)
endef

$(foreach mode,dev pub,$(eval $(pages-template)))


# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------

vpath %.js scripts bower_components/cannot/scripts

script-files := main.js $(wildcard bower_components/*/index.js)

dev-webpack-flags := --debug --output-pathinfo
pub-webpack-flags := --optimize-minimize --optimize-occurence-order

define scripts
  define $(mode)-compile-js
    webpack \
      --bail \
      --define $(mode)=$(mode) \
      $$($(mode)-webpack-flags) \
      --config=$$(filter %/webpack.js,$$^) \
      $$< $$@
  endef

  $(mode)-scripts := out/$(mode)/_scripts.js

  .PHONY: $(mode)-scripts
  $(mode)-scripts: $$($(mode)-scripts)

  out/$(mode)/_scripts.js: main.js $$(script-files) webpack.js | out/$(mode); $$($(mode)-compile-js)
endef

$(foreach mode,dev pub,$(eval $(scripts)))


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
	$(call optimize-png,pub)


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
  $(optimize-png)
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
