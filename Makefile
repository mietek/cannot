.PHONY: all build dev pub clean

all: dev-watch

build: dev-build pub-build

dev: dev-watch

pub: pub-push

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
  kill `cat out/tmp/fswatch.pid 2>/dev/null` \
    2>/dev/null

remember-to-stop-watching = \
  ( \
    while ps -p $${PPID} >/dev/null; do \
      sleep 1; \
    done; \
    $(stop-watching) \
  ) &

start-synchronizing = \
  browser-sync start \
    --no-online \
    --files 'out/$(1)/**/*' \
    --server out/$(1)

pub-git-remote-name = $(shell git config --get cannot.pub.remote)
pub-git-branch      = $(shell git config --get cannot.pub.branch)
pub-git-remote-url  = $(shell git config --get remote.$(pub-git-remote-name).url)

clone-pub-branch = \
  git clone $(pub-git-remote-url) --branch $(pub-git-branch) out/pub \
  && find out/pub \
    | xargs touch -t 0101010101 -am

push-to-pub-branch = \
  [ -z "`git -C out/pub status --porcelain`" ] \
  || \
  ( \
    git -C out/pub add -A . \
    && git -C out/pub commit -m "Make" \
    && git -C out/pub push \
    && git fetch $(pub-git-remote-name) $(pub-git-branch) \
  )


.PHONY: dev-build dev-watch dev-clean

dev-build: dev-pages dev-scripts dev-stylesheets dev-images dev-iconsheet dev-fonts

dev-watch: dev-build
	-$(stop-watching)
	$(call start-watching,dev)
	$(remember-to-stop-watching)
	$(call start-synchronizing,dev)

dev-clean:
	rm -rf out/dev


.PHONY: pub-build pub-clone pub-post-clone pub-push pub-watch pub-clean

pub-build:
	$(MAKE) pub-clone
	$(MAKE) pub-post-clone

pub-clone: out/pub

out/pub:
	$(clone-pub-branch)

pub-post-clone: pub-pages pub-scripts pub-stylesheets pub-images pub-iconsheet pub-fonts

pub-push: pub-build
	$(push-to-pub-branch)

pub-watch: pub-build
	-$(stop-watching)
	$(call start-watching,pub)
	$(remember-to-stop-watching)
	$(call start-synchronizing,pub)

pub-clean:
	rm -rf out/pub


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

dev-advdef-flags := --iter=1
pub-advdef-flags := --iter=100

optimize-zip = \
  advdef \
    $($(1)-advdef-flags) \
    --shrink-insane \
    --quiet \
    -z \
    $@

create-zip = \
  gzip \
    --fast \
    --force \
    --keep \
    --no-name \
    --to-stdout \
    $< \
    >$@ \
  && $(optimize-zip)

optimize-png = \
  optipng \
    -clobber \
    -o6 \
    -strip all \
    -quiet \
    $@ \
  && $(optimize-zip)

optimize-jpg = \
  jpegoptim \
    -m90 \
    --strip-all \
    --quiet \
    $@

optimize-css = \
  cleancss \
    --s0 \
    --skip-rebase \
    --output $@ \
    $<

prefix-css = \
  autoprefixer \
    --browsers '> 1%, last 2 versions, Firefox ESR' \
    --output $@ \
    $<

extract-comments = \
  grep -Eo '/\* $(1): .* \*/' $< \
  | sed -E 's/^.*: (.*) .*$$/\1/' \
  | sort -u >$@

extract-resources = \
  grep -Eo 'url\($(1)/[^)]+\)' $< \
  | sed -E 's,^.*/(.*)\).*$$,\1,' \
  | sort -u >$@ \
  || touch $@


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

compile-md = \
  pandoc \
    --metadata=$(1):$(1) \
    --metadata=project-name:$(notdir $(CURDIR)) \
    --metadata=path:$(subst index.html,,$(patsubst out/$(1)/%,%,$@)) \
    $(foreach metadatum,$(filter %.txt,$^),--metadata=$(patsubst %.txt,%,$(notdir $(metadatum))):"`cat $(metadatum)`") \
    --from=markdown+auto_identifiers+header_attributes \
    $(foreach include,$(filter %.html,$(filter-out %/main.html,$^)),--metadata=$(patsubst %.html,%,$(notdir $(include))):"`cat $(include)`") \
    --to=html5 \
    --section-divs \
    --standalone \
    --template=$(filter %/main.html,$^) \
    --output $@ \
    $<

local-page-metadata  = $(wildcard page-metadata/*.txt)
global-page-metadata = $(filter-out $(addprefix %/,$(local-page-metadata)),$(wildcard bower_components/cannot/page-metadata/*.txt))

page-metadata = $(local-page-metadata) $(global-page-metadata)

page-files := $(call find-files,pages,*.md)
page-paths := index.md error.md license/index.md $(subst pages/,,$(page-files))

pages = $(patsubst %.md,out/$(1)/%.html,$(page-paths))

page-structure := main.html menu-items.html head-extra.html header-extra.html footer-extra.html


dev-page-metadata := $(call page-metadata,dev)
dev-pages         := $(call pages,dev)

.PHONY: dev-pages
dev-pages: $(dev-pages)

out/dev/%.html: %.md $(page-structure) $(dev-page-metadata) | out/dev
	[ -d $(@D) ] || mkdir -p $(@D)
	$(call compile-md,dev)


pub-page-metadata := $(call page-metadata,pub)
pub-pages         := $(call pages,pub)

.PHONY: pub-pages
pub-pages: $(pub-pages)

out/pub/%.html: %.md $(page-structure) $(pub-page-metadata) | out/pub
	[ -d $(@D) ] || mkdir -p $(@D)
	$(call compile-md,pub)


# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------

vpath %.js scripts bower_components/cannot/scripts

dev-webpack-flags := --debug --output-pathinfo
pub-webpack-flags := --optimize-minimize --optimize-occurence-order

compile-js = \
  webpack \
    --define $(1)=$(1) \
    $($(1)-webpack-flags) \
    --bail \
    --config=$(filter %/webpack.js,$^) \
    $< \
    $@

script-files := main.js $(wildcard bower_components/*/index.js)


.PHONY: dev-scripts
dev-scripts: out/dev/_scripts.js

out/dev/_scripts.js: main.js $(script-files) webpack.js | out/dev
	$(call compile-js,dev)


.PHONY: pub-scripts
pub-scripts: out/pub/_scripts.js.gz

out/pub/_scripts.js: main.js $(script-files) webpack.js | out/pub
	$(call compile-js,pub)


# ---------------------------------------------------------------------------
# Iconsheet helper (dev)
# ---------------------------------------------------------------------------

vpath %.txt image-metadata bower_components/cannot/image-metadata

write-iconsheet-helper = \
  echo '$$icon-shapes: ' >$@ \
  && cat $(filter %/icon-shapes.txt,$^) >>$@ \
  && echo ';' >>$@ \
  && echo '$$icon-colors: ' >>$@ \
  && cat $(filter %/icon-colors.txt,$^) >>$@ \
  && echo ';' >>$@


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

compile-sass = \
  sass \
    --line-numbers \
    --sourcemap=none \
    --style expanded \
    --cache-location out/tmp/$(1)/.sass-cache \
    $(addprefix --load-path ,$(helper-roots)) \
    $< \
    $@


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
dev-images  = out/dev/favicon.ico $(addprefix out/dev/_images/,$(image-names))
pub-images  = out/pub/favicon.ico $(addprefix out/pub/_images/,$(image-names) $(addsuffix .gz,$(filter %.svg,$(image-names))))

write-image-target = \
  echo '$(1)-images: $$($(1)-images)' >>$@

write-image-targets = \
  echo >$@ \
  && $(call write-image-target,dev) \
  && $(call write-image-target,pub)


.PHONY: dev-images
.PHONY: pub-images
out/tmp/images.mk: out/tmp/image-names.txt
	$(write-image-targets)

-include out/tmp/images.mk


out/dev/%.ico: %.ico | out/dev
	cp $< $@

out/dev/_images/%.png: %.png | out/dev/_images
	cp $< $@
	$(call optimize-png,dev)

out/dev/_images/%: % | out/dev/_images
	cp $< $@


out/pub/%.ico: %.ico | out/pub
	cp $< $@

out/pub/_images/%.jpg: %.jpg | out/pub/_images
	cp $< $@
	$(optimize-jpg)

out/pub/_images/%.png: %.png | out/pub/_images
	cp $< $@
	$(call optimize-png,pub)

out/pub/_images/%: % | out/pub/_images
	cp $< $@


# ---------------------------------------------------------------------------
# Iconsheet
# ---------------------------------------------------------------------------

icon-shapes       = $(shell cat out/tmp/$(1)/icon-shapes.txt)
icon-colors       = $(shell cat out/tmp/$(1)/icon-colors.txt)
icon-column-names = $(patsubst %,icon-$(shape)-%$(2).png,$(icon-colors))
icon-names        = $(foreach shape,$(icon-shapes),$(icon-column-names))
icon-column-files = $(foreach name,$(icon-column-names),$(filter %/$(name),$^))

compile-iconsheet = \
  convert \
    $(foreach shape,$(icon-shapes),\( $(icon-column-files) -append \)) \
    +append $@ \
  && $(optimize-png)

write-iconsheet-target = \
  echo 'out/$(1)/_images/iconsheet$(2).png: $$(call icon-names,$(1),$(2)) | out/$(1)/_images' >>$@ \
  && echo '	$$(call compile-iconsheet,$(1),$(2))' >>$@

write-iconsheet-targets = \
  echo >$@ \
  && $(call write-iconsheet-target,$(1),) \
  && $(call write-iconsheet-target,$(1),@2x)


.PHONY: dev-iconsheet
dev-iconsheet: out/dev/_images/iconsheet.png out/dev/_images/iconsheet@2x.png

out/tmp/dev/%.txt: %.txt | out/tmp/dev
	cp $< $@

out/tmp/dev/iconsheet.mk: out/tmp/dev/icon-shapes.txt out/tmp/dev/icon-colors.txt
	$(call write-iconsheet-targets,dev)

-include out/tmp/dev/iconsheet.mk


.PHONY: pub-iconsheet
pub-iconsheet: out/pub/_images/iconsheet.png out/pub/_images/iconsheet@2x.png

out/tmp/pub/iconsheet.mk: out/tmp/pub/icon-shapes.txt out/tmp/pub/icon-colors.txt
	$(call write-iconsheet-targets,pub)

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
dev-fonts  = $(addprefix out/dev/_fonts/,$(font-names))
pub-fonts  = $(addprefix out/pub/_fonts/,$(font-names))

write-font-target = \
  echo '$(1)-fonts: $$($(1)-fonts)' >>$@

write-font-targets = \
  echo >$@ \
  && $(call write-font-target,dev) \
  && $(call write-font-target,pub)


.PHONY: dev-fonts
.PHONY: pub-fonts
out/tmp/fonts.mk: out/tmp/font-names.txt
	$(write-font-targets)

-include out/tmp/fonts.mk


out/dev/_fonts/%.woff: %.woff | out/dev/_fonts
	cp $< $@

out/pub/_fonts/%.woff: %.woff | out/pub/_fonts
	cp $< $@
