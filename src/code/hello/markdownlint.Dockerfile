# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

FROM ruby:3.0.0-alpine3.13

RUN gem install mdl

ENTRYPOINT ["mdl"]
