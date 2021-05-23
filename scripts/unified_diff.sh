# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 <img-name> <tag>` builds a docker image that replaces the docker image
# `<img-name>:<tag>`, or creates it if it doesn't already exist.
#
# This script uses `<img-name>:cached` as a temporary tag and so may clobber
# such existing images if present.

# We use `tail -n +4` to skip the first 3 lines of the output, which contain
# context of the diff.
diff \
    --unified=$(cat "$1" | wc -l) \
    "$1" \
    "$2" \
    | tail \
        -n +4
