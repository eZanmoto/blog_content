---
title: "`with_build_env.sh`"
date: 2021-05-23
tags:
- bash
- devops
- docker
- script
- shell
---

In [Docker for the Build Process](../docker_for_building), I introduced the idea
of extracting the build phase of a project into a dedicated `build_img.sh`
script, which uses the project's Dockerised build environment to build the "run"
image for the project, allowing a project to be built on a host environment
without installing any extra tooling other than Docker. In this post I'll expand
on this idea and show how we can use this script as a basis for a new, reusable
script that allows us to easily work with the build environment of our project.

Basic Usage
-----------

The idea here is to create a `with_build_env.sh` script which, at its most
basic, will take a command and run it in the build environment, with the local
project directory also mounted in this build environment. This means that we
could, for example, run `bash scripts/with_build_env.sh make` without even
installing `make` locally, but have all the artefacts output to our local
project directory.

### Headless usage

The first way this script can be run is the "headless" way, which is the
approach that will be primarily used in the build pipeline. This runs a
command in the build environment:

```bash
bash scripts/with_build_env.sh make posts
```

More complicated commands involving Bash operators can also be performed using
the likes of `bash -c`:

```bash
bash scripts/with_build_env.sh bash -c 'make check && make posts'
```

### Interactive usage

The second way this script can be run is the "interactive" way, which will
only be used locally in general. This typically involves running an interactive
shell in the build environment. This will allow you to run build environment
tools on your project, even if they're not installed on your local environment.

This approach will usually be performed using `sh`/`bash` as the command, and
using a flag to indicate that the current command should be run interactively:

```bash
bash scripts/with_build_env.sh --dev bash
```

This launches a Bash process in the build environment. This allows you to work
within your local directory but use the tools from your build environment.

The reason for using a flag to distinguish interactive use from headless use is
that build pipelines generally don't provide a certain mechanism (a TTY) for
interactive use, so attempting to run a command in interactive mode in the build
pipeline will fail.

Basic Implementation
--------------------

The following is a basic `with_build_env.sh` script based on the ideas presented
in [Docker for the Build Process](../docker_for_building):

```bash
<!snippet code/hello/scripts/with_build_env_basic.sh 11 18 rUUdZt1Cwzx7bXWVQeqzmwkv6fs=>
```

This just performs two actions: it rebuilds the image for the build environment,
if necessary, and then runs the provided command in the build environment.
Rebuilding the image isn't necessary if you're using a remote image, but this
step is useful for keeping your image up-to-date if your project defines its own
build environment, as it's common for the requirements of projects to grow
beyond base images quite quickly.

Using this script to build the current project can then be as straightforward as
`bash scripts/with_build_env.sh make`. However, there are a number of drawbacks
to the script as it currently is, such as the fact that the build runs as `root`
and dependencies aren't cached. The following sections show optional,
incremental steps that can be used to improve this basic implementation.

One additional note about `with_build_env.sh` is that, while the general idea
and approach of each instance of the script is the same, each specific instance
of the script may vary. This is because the utility of this script will
generally change from project to project and language to language. For example,
when a `with_build_env.sh` script wants to keep the build cache between Docker
runs, the specifics of where the cache lives is handled directly by the
`with_build_env.sh` script, and this changes depending on the language and build
tooling being used.

Layers
------

The basic `with_build_env.sh` script presented above gives a lot of the benefits
touted in [Docker for the Build Process](../docker_for_building) right out of
the box. However, you are likely to encounter different issues depending on
exactly how you'll be using the script. For example, the first issue that is
likely to be encountered when working with this script is to try and run it in a
build pipeline, which will probably result in Docker failing with an error
output of `the input device is not a TTY`. Another problem is that the issued
command is run by `root` by default which, while not necessarily a problem in
and of itself, can cause a little friction when files created in the build
environment are owned by `root` in the host directory. This section outlines the
most common and problematic issues that may be encountered, along with possible
resolutions.

### Interactive use

The first issue that is often encountered when working with the
`with_build_env.sh` script is the fact that Docker will need the `--interactive`
and `--tty` flags when running locally, but will need them to be removed when
running in the build pipeline. For this I generally introduce some basic
argument parsing to the script to allow it to either be run in "dev"
(interactive) mode, or not:

```diff
<!snippet ../target/gen/diffs/with_build_env_basic_to_dev.diff 15 27 ypsHMLwMYNQApnTULRQip0qMFYA=>
```

Passing `--interactive` and `--tty` is sufficient for enabling this
functionality, but I have a convention of also having the `--dev` option take a
port forwarding argument, which is used to expose a port from the container.
This is because I often find myself making use of ports to achieve some level of
communication between the host and the container, such as running the main
service I'm working on in the build environment and accessing it from the host.
This addition does mean that the command for launching an interactive Bash shell
has to be modified slightly, but it also means that we avoid having to restart
the session in order to expose the container to the host:

```bash
bash scripts/with_build_env.sh --dev 3000:3000 bash
```

### User mapping

This isn't as much of an issue in the build pipeline, but when using the
`with_build_env.sh` script as presented above, one issue is that the default
user in the build environment is `root`. This is fine in a functional sense -
you'll generally be able to build the project without issue and won't run into
ownership problems. However, it quickly becomes very tedious from a usability
perspective - any files that are created in the container are owned by `root`,
requiring `sudo` to remove them locally, and accidentally performing `git`
operations can result in pain down the line as some of the files in your `.git`
directory can have their ownership altered.

As a more usable solution I usually pass `--user="$(id --user):$(id --group)"`
to the `docker run` command. This means that we're now running as our host user
when using the build environment, so any files we create will have the desired
ownership:

```diff
<!snippet ../target/gen/diffs/with_build_env_dev_to_user.diff 32 9 KKw8NSG6eG5m+K3r2oDRvsNdGVE=>
```

#### User mapping caveats

One issue with mapping the user as presented is that, while we're using the
correct user and group IDs in the container for local development, this user
doesn't actually exist within the build environment. This means that any tools
that rely on the user's `$HOME`, including many Git and SSH-based commands,
simply won't work. Such commands will either need to be run outside the build
environment (such as `git commit`), or else the build environment will need to
be set up with a functional user to carry out specific commands with `sudo`.
It's not always necessary for the user to exist in the container, but if it is
then [that user can be created in the build environment with the desired user ID
and group
ID](https://jtreminio.com/blog/running-docker-containers-as-current-host-user/#make-it-dynamic).

### Caching

A convention of `with_build_env.sh` is to `--rm` containers after each use,
which is useful to avoid accidentally depending on ephemeral aspects of the
build environment. However, this means that any project dependencies stored
outside the project directory must be re-downloaded with each launch of the
build environment.

The solution to this is to cache the downloaded files. This is a big area where
the script will change based on the programming language and tooling being used.

The first step is to create an area to persist the cached directories. For this
I create named volumes with open permissions:

```bash
<!snippet code/hello/scripts/with_build_env_go.sh 31 14 7eraz1wvCNcM2aJGYO9IPxI5wK4=>
```

The specific image being used here isn't important (it just needs to have
`chmod` present) but we use the build environment for this for simplicity. We
give the directory open permissions because volumes are owned by `root` when
created by docker, and we want to allow any user to be able to download
dependencies and run builds in the build environment.

It's also useful to prefix the name of the volume with the name of the project
(`ezanmoto.hello.`, in this example) to help isolate builds across project
boundaries. See the "Caveats" section, below, for more details.

The last piece of the puzzle then is to mount the volume when using the build
environment, and to let the build tools that we're using know about this:

```diff
<!snippet ../target/gen/diffs/with_build_env_user_to_go.diff 48 11 tMjpAWxn+qgBm/e3nlAYTciu4CI=>
```

We can see that the Go build tools are told about the cache directory through
the use of the `XDG_CACHE_HOME` environment variable.

This setup allows the persistence of project dependencies across `docker run`s
without baking them into the image or storing them locally. The cache can also
be cleared by running `docker volume rm ezanmoto.hello.tmp_cache
ezanmoto.hello.pkg_cache`, and the cache area will be automatically
remade the next time `with_build_env.sh` runs.

#### Rust

The following shows how a similar caching mechanism could be implemented for
Rust. This snippet is taken from [another project of
mine](https://github.com/eZanmoto/dpnd/blob/4b54199c782f8a2c3f94be2a7c4632cd551013aa/scripts/with_build_env.sh):

```bash
<!snippet ../target/gen/deps/dpnd_with_build_env.sh 17 17 bIUcNn9yZtajiUtIWOYxYZsI+L8=>
```

It can be seen that Rust uses the `CARGO_HOME` environment variable to locate
the cache.

#### Caveats of cache volumes

It should generally be fine to use the same cache across projects, but some
tools can encounter difficulties when the same caching volume is shared between
projects (I've experienced this when using Go in particular, where I've
encountered issues with the checksum database).

The simplest solution in this scenario is to prefixing the volume name with the
name of the project in order to isolate volumes per project. However, do note
that this issue can still arise even in a single project - for example, when
changing between branches with different lockfiles. In this scenario it's
helpful to remove the cache volume and allow `with_build_env.sh` to recreate it:

```bash
docker volume rm ezanmoto.hello.tmp_cache ezanmoto.hello.pkg_cache
```

Benefits
--------

An immediate benefit of `with_build_env.sh` is that, assuming direct Docker
access is available to us in the build pipeline, we can use the same commands
locally those used in the build pipeline. This makes our pipeline easier to set
up, but also means that we can run our local code in the build environment
before we commit to help ensure that code that builds locally will also build in
the build pipeline.

Some other benefits:

* We have a simpler mechanism to open a shell in the build environment, which
  can be used for building, testing and debugging.

* We can more easily work with a project without having to manually install its
  dependencies and required tools, which helps us avoid issues when trying to
  run the project for the first time. This is particularly helpful for
  onboarding new developers.

* Many of the benefits outlined in [Docker for the Build
  Process](../docker_for_building) also apply. In particular, it now becomes
  much easier to start the interactive build environment.

Conclusion
----------

The `with_build_env.sh` script allows us to abstract the process of running
commands inside the build environment, making it easier for us to build, run and
debug code in the replicated build environment. This enables greater parity with
the build pipeline, and further helps to avoid the classic "it works on my
machine" issue.
