# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

set -o errexit

proj='ezanmoto/hello'
build_img="$proj.build"
run_img="$proj"

bash scripts/docker_rbuild.sh \
    "$build_img" \
    "latest" \
    --file='build.Dockerfile' \
    .

mkdir -p target
docker run \
    --rm \
    --mount="type=bind,src=$(pwd),dst=/go/src/github.com/ezanmoto/hello" \
    "$build_img:latest" \
    bash -c '
        set -o errexit

        go mod download
        CGO_ENABLED=0 go build -o target ./...
    '

bash scripts/docker_rbuild.sh \
    "$run_img" \
    'latest' \
    .
