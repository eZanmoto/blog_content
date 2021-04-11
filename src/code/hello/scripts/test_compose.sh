# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0` runs a new instance of the run image for this project and verifies that
# it can be reached.

set -o errexit

proj='ezanmoto/hello'
run_img="$proj"

cont_id=$(
    docker run \
        --rm \
        --detach \
        --publish=3000:3000 \
        "$run_img"
)

kill_cont() {
    docker logs "$cont_id" \
        | sed 's/^/[>] /'
    docker kill "$cont_id"
}
trap kill_cont EXIT

curl \
    --fail \
    http://localhost:3000
