# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 [--dev <port-forwarding>]` runs a command in the build environment.
#
# The `dev` argument runs the build environment in interactive mode with a new
# TTY, and with the specified `port-forwarding` (i.e. `80:8080` forwards the
# local port 80 to port 8080 inside the build environment).

set -o errexit

docker_flags=''
case "$1" in
    --dev)
        docker_flags="$docker_flags --interactive --tty --publish=$2"
        shift 2
        ;;
esac

org='ezanmoto'
proj='hello'
build_img="$org/$proj.build"

bash scripts/docker_rbuild.sh \
    "$build_img" \
    "latest" \
    --file='build.Dockerfile' \
    .

tmp_cache="$org.$proj.tmp_cache"
pkg_cache="$org.$proj.pkg_cache"
tmp_cache_dir='/tmp/cache'
pkg_cache_dir='/go/pkg'

docker run \
    --rm \
    --mount="type=volume,src=$tmp_cache,dst=$tmp_cache_dir" \
    --mount="type=volume,src=$pkg_cache,dst=$pkg_cache_dir" \
    "$build_img:latest" \
    chmod \
        0777 \
        "$tmp_cache_dir" \
        "$pkg_cache_dir"

workdir='/go/src/github.com/ezanmoto/hello'

docker run \
    $docker_flags \
    --rm \
    --env=XDG_CACHE_HOME="$tmp_cache_dir" \
    --mount="type=volume,src=$tmp_cache,dst=$tmp_cache_dir" \
    --mount="type=volume,src=$pkg_cache,dst=$pkg_cache_dir" \
    --user="$(id --user):$(id --group)" \
    --mount="type=bind,src=$(pwd),dst=$workdir" \
    --workdir="$workdir" \
    "$build_img:latest" \
    "$@"
