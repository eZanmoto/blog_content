# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0` runs a command in the build environment.
#
# Note that care should be taken because the command is run as `root`.

set -o errexit

org='ezanmoto'
proj='hello'
build_img="$org/$proj.build"

bash scripts/docker_rbuild.sh \
    "$build_img" \
    "latest" \
    --file='build.Dockerfile' \
    .

workdir='/go/src/github.com/ezanmoto/hello'

docker run \
    --rm \
    --mount="type=bind,src=$(pwd),dst=$workdir" \
    --workdir="$workdir" \
    "$build_img:latest" \
    "$@"
