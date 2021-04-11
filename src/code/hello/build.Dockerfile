# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

FROM golang:1.14.3-stretch

RUN \
    apt-get update \
    && apt-get install -y \
        fortune-mod \
    && ln -s /usr/games/fortune /bin/fortune

ENV GO111MODULE=on

WORKDIR /go/src/github.com/ezanmoto/hello
