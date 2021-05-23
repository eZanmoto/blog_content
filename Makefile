# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# This file uses static pattern rules instead of pattern rules in order to
# prevent `make` from removing intermediate files. See
# <https://stackoverflow.com/a/34983297> for more details.

proj_dir:=$(shell pwd)
src_dir:=src
tgt_dir:=target
tgt_gen_dir:=$(tgt_dir)/gen

src_mds:=$(shell find $(src_dir)/posts -name '*.md')
src_code:=$(shell find $(src_dir)/code)
src_diffs:=$(shell find $(src_dir)/code -name '*.diff')

tgt_mds:=$(patsubst $(src_dir)/posts/%.md,$(tgt_gen_dir)/posts/%.md,$(src_mds))
tgt_diffs:=$(patsubst $(src_dir)/code/%.diff,$(tgt_gen_dir)/diffs/%.diff,$(src_diffs))

.PHONY: all
all: \
		check \
		$(tgt_gen_dir)/index.njk \
		posts \
		| $(tgt_gen_dir)

.PHONY: posts
posts: $(tgt_mds)

$(tgt_gen_dir)/index.njk: src/index.njk | $(tgt_gen_dir)
	cp '$<' '$@'

# We change to the `src_dir` directory to run `insert_snippets.py` so that paths
# to snippets will be evaluated relative to `src_dir`.
#
# We redirect output to `$@_` instead of `$@` so that the destination file isn't
# updated in the case of an error. If this isn't done then `make` won't attempt
# to regenerate the file after a failure, since the target file would be newer
# than the source.
$(tgt_mds): $(tgt_gen_dir)/posts/%.md: \
		$(src_dir)/posts/%.md \
		$(src_code) \
		scripts/insert_snippets.py \
		$(tgt_diffs) \
		| $(tgt_gen_dir)/posts
	( \
		cd '$(src_dir)' ; \
		python3 '$(proj_dir)/scripts/insert_snippets.py' \
			'$(patsubst $(src_dir)/%,%,$<)' \
			$(if $(SKIP_CHECKSUM),--skip-checksum) \
			> '../$@_' \
	)
	mv '$@_' '$@'

# See above for the reason we redirect output to `$@_` instead of `$@`.
$(tgt_diffs): $(tgt_gen_dir)/diffs/%.diff: \
		$(src_dir)/code/%.diff \
		$(src_code) \
		$(tgt_gen_dir)/deps/dpnd_with_build_env.sh \
		| $(tgt_gen_dir)/diffs
	mkdir -p '$(dir $@)'
	sh scripts/unified_diff.sh \
		'$(shell head -1 $<)' \
		'$(shell tail -1 $<)' \
		> '$@_'
	mv '$@_' '$@'

$(tgt_gen_dir)/deps/dpnd_with_build_env.sh: | $(tgt_gen_dir)/deps
	wget \
		-O '$@' \
		https://raw.githubusercontent.com/eZanmoto/dpnd/4b54199c782f8a2c3f94be2a7c4632cd551013aa/scripts/with_build_env.sh

$(tgt_gen_dir)/deps: | $(tgt_gen_dir)
	mkdir '$@'

$(tgt_gen_dir)/posts: | $(tgt_gen_dir)
	mkdir '$@'

$(tgt_gen_dir)/diffs: | $(tgt_gen_dir)
	mkdir '$@'

$(tgt_gen_dir): | $(tgt_dir)
	mkdir '$@'

$(tgt_dir):
	mkdir '$@'

.PHONY: check
check: \
		check_lint \
		check_py_snippets

.PHONY: check_lint
check_lint:
	markdownlint \
		--config=configs/markdownlint.json \
		'*.md' \
		'$(src_dir)/**/*.md'

.PHONY: check_py_snippets
check_py_snippets:
	for py in $$(find '$(src_dir)/code' -name '*.py') ; do \
		python3 "$$py" \
			|| exit 1 ; \
	done

# NOTE This test isn't run as part of `all`, but instead must be run separately
# because the build environment doesn't nest Docker at present.
.PHONY: check_hello
check_hello:
	( \
		cd '$(src_dir)/code/hello' \
			&& bash scripts/test.sh \
	)
