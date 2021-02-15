# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

proj_dir:=$(shell pwd)
src_dir:=src
tgt_dir:=target
tgt_gen_dir:=$(tgt_dir)/gen

src_mds:=$(shell find $(src_dir)/posts -name '*.md')

tgt_mds:=$(patsubst $(src_dir)/posts/%.md,$(tgt_gen_dir)/posts/%.md,$(src_mds))

.PHONY: all
all: \
		check \
		$(tgt_gen_dir)/index.njk \
		$(tgt_mds) \
		| $(tgt_gen_dir)

$(tgt_gen_dir)/index.njk: src/index.njk | $(tgt_gen_dir)
	cp '$<' '$@'

# We change to the `src_dir` directory to run `insert_snippets.py` so that paths
# to snippets will be evaluated relative to `src_dir`.
#
# We redirect output to `$@_` instead of `$@` so that the destination file isn't
# updated in the case of an error. If this isn't done then `make` won't attempt
# to regenerate the file after a failure, since the target file would be newer
# than the source.
$(tgt_gen_dir)/posts/%.md: \
		$(src_dir)/posts/%.md \
		$(shell find $(src_dir)/code) \
		scripts/insert_snippets.py \
		| $(tgt_gen_dir)/posts
	( \
		cd '$(src_dir)' ; \
		python3 '$(proj_dir)/scripts/insert_snippets.py' \
			'$(patsubst $(src_dir)/%,%,$<)' \
			$(if $(SKIP_CHECKSUM),--skip-checksum) \
			> '../$@_' \
	)
	mv '$@_' '$@'

$(tgt_gen_dir)/posts: | $(tgt_gen_dir)
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
