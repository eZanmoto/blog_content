# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

if [ $# -ne 1 ] ; then
    echo "usage: $0 <md-file>" >&2
    exit 1
fi
md_file="$1"

proj='ezanmoto/hello'
sub_img_name="markdownlint"
sub_img="$proj.$sub_img_name"

bash scripts/docker_rbuild.sh \
    "$sub_img" \
    'latest' \
    --file="$sub_img_name.Dockerfile" \
    .

docker run \
    --rm \
    --volume="$(pwd):/app" \
    --workdir='/app' \
    "$sub_img" \
    "$md_file"
