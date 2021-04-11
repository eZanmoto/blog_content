# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

set -o errexit

proj='ezanmoto/hello'
run_img="$proj"

bash scripts/docker_rbuild.sh \
    "$run_img" \
    'latest' \
    .

docker-compose up "$@"
