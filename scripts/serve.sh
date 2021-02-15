# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0` runs `eleventy` to serve files from `target/gen` for debugging purposes.
# It outputs the rendered files to `target/site` as a side-effect.

# TODO Note that hot reloading of browser pages isn't currently supported
# because content isn't wrapped in `body` tags
# (<https://github.com/11ty/eleventy/issues/726#issuecomment-656969512>). This
# can be resolved by adding a global layout that adds these tags automatically
# (<https://github.com/11ty/eleventy/issues/701#issuecomment-612621290>).

# We `cd` to `target` instead of using `--input=target/gen` and
# `--output=target/site` because the latter causes `eleventy` to skip reading
# and writing the expected files.
cd target
eleventy \
    --input=gen \
    --output=site \
    --serve \
    --quiet
