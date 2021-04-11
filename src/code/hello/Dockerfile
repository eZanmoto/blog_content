# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

FROM alpine:3.11.3

RUN apk add fortune

COPY target/hello /bin

ENTRYPOINT ["/bin/hello"]
