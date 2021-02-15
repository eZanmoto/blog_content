# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 [--dev <port>]` runs a command in the build environment.
#
# The `dev` argument runs the build environment in interactive mode with a new
# TTY, and with the specified `port`.

set -o errexit

docker_flags=''
case "$1" in
    --dev)
        docker_flags="$docker_flags --interactive --tty --publish=$2"
        shift 2
        ;;
esac

build_img='ezanmoto/blog_content.build'

bash scripts/docker_rbuild.sh \
    "$build_img" \
    "latest" \
    --file='build.Dockerfile' \
    scripts

docker run \
    $docker_flags \
    --rm \
    --user="$(id -u):$(id -g)" \
    --mount="type=bind,src=$(pwd),dst=/app" \
    --workdir='/app' \
    "$build_img:latest" \
    "$@"
