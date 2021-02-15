# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

FROM node:15.5.1-alpine3.10

RUN \
    apk add \
        --update \
        --no-cache \
        entr=4.2-r0 \
        make=4.2.1-r2 \
        python3=3.7.7-r1 \
    && npm install \
        --global \
        @11ty/eleventy@0.11.1 \
        markdownlint-cli@0.26.0
