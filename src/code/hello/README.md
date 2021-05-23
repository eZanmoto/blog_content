README
======

About
-----

This is a sample project to demonstrate the use of `docker_rbuild.sh`. It
defines a HTTP service that returns "fortune cookie" outputs.

Usage
-----

The build environment for the project is defined in `build.Dockerfile`. The
build environment can be replicated locally by following the setup defined in
the Dockerfile, or Docker can be used to mount the local directory in the build
environment by running the following:

```bash
bash scripts/with_build_env_basic.sh --dev 8080:8080 sh
```

This will also forward the local 8080 port to port 8080 inside the container.
