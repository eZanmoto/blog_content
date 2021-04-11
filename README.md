Blog Content
============

About
-----

This project contains the content for the blog at <https://seankelleher.ie>.

The core content is stored in `src` and is built to directories in `target/gen`.
This project intentionally doesn't contain any style/rendering information,
which is added in a separate step.

Usage
-----

### Build environment

The build environment for the project is defined in `build.Dockerfile`. The
build environment can be replicated locally by following the setup defined in
the Dockerfile, or Docker can be used to mount the local directory in the build
environment by running the following:

    bash scripts/with_build_env.sh --dev 8080:8080 sh

This will also forward the local 8080 port to port 8080 inside the container.

### Building

The content can be built locally by running `make`, or can be built using Docker
by running the following:

    bash scripts/with_build_env.sh make

Building the project generates rendered files, including `md` files, to
`target/gen`. These rendered files can then be include in a further build
involving templates to produce HTML content.

Note that regular builds will validate snippet checksums to ensure reproducible
builds (see `scripts/insert_snippets.py` for more details). This can be disabled
during development by using `make SKIP_CHECKSUM=1`.

An alternate source directory can be provided for working on drafts by providing
it as `src_dir` to `make`, for example `make src_dir=_drafts`.

### Developing

`eleventy` is used to debug the formatting of the generated output. The test
server can be run using `sh scripts/serve.sh`. Note that this will only reload
when new rendered data is generated, so updating the served content will also
require a call to `make`. `make` can be called automatically whenever content in
`src` changes by running the following:

    find src | entr make SKIP_CHECKSUM=1

Note that automatic browser refreshes aren't currently supported; see
`scripts/serve.sh` for more information.

### `make check_hello`

In general, the `check` target in the `Makefile` is run as part of a regular
`make` run, which runs all `check_*` targets. However, one exception to this is
the `check_hello`, and it isn't run by default because it requires Docker to be
available as part of the test execution, and the build environment doesn't
contain a Docker client. While it's possible to [safely run a Docker client
within a
container](http://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/#the-socket-solution),
the general approach to this requires special handling in order to correctly
address bind-mounted volumes, which would complicate the sample code presented
in the blog. As such, this simplified approach is taken where the `check_hello`
target is expected to be run in an environment that has Docker available,
separately to the regular build environment.
