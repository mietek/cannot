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
  kill `cat out/tmp/fswatch.pid 2>/dev/null` 2>/dev/null

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


.PHONY: dev-watch
dev-watch: dev-build
	-$(stop-watching)
	$(call start-watching,dev)
	$(remember-to-stop-watching)
	$(call start-synchronizing,dev)

.PHONY: pub-watch
pub-watch: pub-build
	-$(stop-watching)
	$(call start-watching,pub)
	$(remember-to-stop-watching)
	$(call start-synchronizing,pub)


# ---------------------------------------------------------------------------
# Publishing
# ---------------------------------------------------------------------------

pub-remote-name = $(shell git config --get cannot.pub.remote)
pub-remote-url  = $(shell git config --get remote.$(pub-remote-name).url)
pub-branch      = $(shell git config --get cannot.pub.branch)

init-pub-branch = \
  git checkout --orphan gh-pages \
  && git config --add cannot.pub.remote origin \
  && git config --add cannot.pub.branch gh-pages \
  && git rm -rf . \
  && touch .nojekyll \
  && git add .nojekyll \
  && git commit -m "Initial commit" \
  && git push -u origin gh-pages \
  && git checkout master \
  && git branch -d gh-pages

clone-pub-branch = \
  git clone $(pub-remote-url) -b $(pub-branch) --single-branch out/pub \
  && find out/pub \
    | xargs touch -t 0101010101 -am

push-to-pub-branch = \
  [ -z "`git -C out/pub status --porcelain`" ] \
  || \
  ( \
    git -C out/pub add -A . \
    && git -C out/pub commit -m "Make" \
    && git -C out/pub push \
    && git fetch $(pub-remote-name) $(pub-branch) \
  )


.PHONY: pub-init
pub-init:
	$(init-pub-branch)

out/pub:
	$(clone-pub-branch)

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

page-metadata := $(wildcard page-metadata/*.txt)

page-files := $(call find-files,pages,*.md)
page-paths := index.md error.md license/index.md $(subst pages/,,$(page-files))

pages = $(patsubst %.md,out/$(1)/%.html,$(page-paths))

page-structure := main.html menu-items.html head-extra.html header-extra.html footer-extra.html


dev-pages         := $(call pages,dev)

.PHONY: dev-pages
dev-pages: $(dev-pages)

out/dev/%.html: %.md $(page-structure) $(page-metadata) | out/dev
	[ -d $(@D) ] || mkdir -p $(@D)
	$(call compile-md,dev)


pub-pages         := $(call pages,pub)

.PHONY: pub-pages
pub-pages: $(pub-pages)

out/pub/%.html: %.md $(page-structure) $(page-metadata) | out/pub
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

icon-shapes = $(shell cat out/tmp/$(1)/icon-shapes.txt)
icon-colors = $(shell cat out/tmp/$(1)/icon-colors.txt)

icon-cell-files   = $(patsubst %,icon-$${shape}-%$(2).png,$(icon-colors))
icon-column-files = $(foreach shape,$(icon-shapes),out/tmp/$(1)/icon-column-$(shape)$(2).png)

compile-icon-column = \
  convert $^ -append $@

compile-iconsheet = \
  convert $^ +append $@ && $(optimize-png)

write-icon-column-target = \
  echo "out/tmp/$(1)/icon-column-$${shape}$(2).png: $(call icon-cell-files,$(1),$(2)) | out/tmp/$(1)" >>$@ \
  && echo '	$$(call compile-icon-column,$(1),$(2))' >>$@

write-icon-column-targets = \
  for shape in $(icon-shapes); do $(write-icon-column-target); done

write-iconsheet-target = \
  echo 'out/$(1)/_images/iconsheet$(2).png: $(call icon-column-files,$(1),$(2)) | out/$(1)/_images' >>$@ \
  && echo '	$$(call compile-iconsheet,$(1),$(2))' >>$@


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
