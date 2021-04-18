---
title: Docker for the Build Process
date: 2021-04-18
tags:
- devops
- docker
---

This article covers the use of Docker as part of the build process, for both
local development and continuous integration builds. In particular, it addresses
the practice of building projects using `docker build`, and the alternative
approach of using `docker run` to perform builds.

Many articles already espouse the benefits of using Docker for local builds, as
part of the "dev loop", but to recap a few:

* Running your local builds in Docker gives you better parity with the central
  build pipeline when the latter is also using Docker.

* Your local builds can run in a minimal environment, reducing dependencies and
  the risk of depending on tools and resources that aren't available in the
  central build pipeline. This also helps with the issue of using mismatched
  versions of tools.

* It's possible to work on a project without having any of the
  tools/languages/frameworks installed locally. This is particularly useful when
  working on projects for a short term, or for working on different projects
  that depend on conflicting versions of the same tools.

Building in Docker Images
-------------------------

When using Docker as part of the build process, some projects build the project
artefacts as part of an image build. A typical `Dockerfile` to define a service
may look like the following:

```dockerfile
<!snippet code/hello/run.Dockerfile 5 21 lOgJ5UGDnGVxzzS97Ugz1nylwFg=>
```

One of the most obvious problems with this approach is that this image defines
both the build environment and the run environment. This leads to a number of
issues such as increased image size, an increased number of attack vectors
(because of all of the extra packages required for the build), and the more
subtle issue of mixing contexts (for example, is a particular dependency
required for the build time or the run time?). Thankfully, Docker added
multi-stage Docker builds, which allows us to separate the definition of the
build image and the run image, and allows us to make the run image as minimal as
possible.

However, another problem exists in the form of the `COPY` commands:

* `<!snippet code/hello/run.Dockerfile 21 1 UgPpKREZ19UG6zQGjHaZoOPjg2M=>` means
  that a new image needs to be built every time we want to use Docker to test a
  code change.

* `<!snippet code/hello/run.Dockerfile 21 1 UgPpKREZ19UG6zQGjHaZoOPjg2M=>`
  actually results in the entire codebase being copied every time that Docker is
  used to build the project (assuming something in the codebase has changed).
  This is more of an issue in bigger projects, where it can take a few seconds
  to copy all files, adding delays to the development loop.

* `docker build` has to be run a lot in this setup for debugging purposes; every
  time you change the `Dockerfile` to try something different you'll need to
  rebuild the image, further compounding any delays encountered by
  re-downloading project dependencies and copying the codebase into the image.
  It's not very interactive.

* `<!snippet code/hello/run.Dockerfile 15 1 47GiEuV1YOgLTQQDBEVorGBNEms=>` can
  be a pain-point when working with Docker images. With dependency managers such
  as `npm install` and `go get` that can handle automatically fetching packages,
  it's useful to be able to quickly try out different combinations. However,
  because the `COPY` step will cause all packages to be re-downloaded instead of
  just the updates, this adds friction, and a resistance to using Docker in the
  development loop, when it comes to testing and updating different
  dependencies.

Building in Docker Containers
-----------------------------

A straightforward alternative is to build artefacts in containers instead of in
images, utilising bind-mounts instead of `COPY`. For example, instead of the
image-based build in the previous section, the following can be used:

`build.Dockerfile`:

```dockerfile
<!snippet code/hello/build.Dockerfile 5 11 2milkCXLgrg9SifG0c9wEpYWF6A=>
```

`build_img.sh`:

```bash
<!snippet code/hello/scripts/build_img.sh 7 26 wmc0/U+BEheI6UvKVFgF5oNjDok=>
```

`Dockerfile`:

```dockerfile
<!snippet code/hello/Dockerfile 5 7 mT6FdnxXLDyB3LjgPU1bNfl1lKc=>
```

There is a notable increase in the amount of code that's present here, but there
are also some immediate benefits:

* Fewer image builds: The build image only needs to be built once, until its
  actual definition changes, as opposed to being built every time there's a code
  change. The run image only needs to be built in the CI environment unless it's
  being tested locally. When debugging the run image, rebuilding the image
  multiple times has less friction because changing files in the project won't
  break the cache.

* No redundant copying: The build is being run using the host directory so the
  delay incurred from copying the build context over and over is avoided,
  without needing to play around with `.dockerignore`.

* Project dependencies that are located within the project directory (e.g.
  `.node_modules`) can be kept from previous runs, even if the dependency/lock
  files change, and even if the definition of the build environment changes.
  Volumes can be used to cache dependencies that exist outside the project
  directory.

Here are some other small benefits that I like:

* Succinct definition of the build environment: This makes it easier for
  developers that prefer to develop locally to actually mirror the exact build
  environment that'll be used in the build pipeline, by following the steps
  outlined in `build.Dockerfile`.

* The definition of the build environment, run environment and build
  instructions are all cleanly separated.

However, the biggest benefit that I get from this approach lies in the fact that
I can use the build environment interactively, as outlined in the following
section.

Interactive Build Environment
-----------------------------

Now that the definition of the build environment has been separated from the
build instructions and the definition of the run environment, it's possible to
work interactively within the build environment with the local project directory
mounted:

```bash
docker run \
    --interactive \
    --tty \
    --rm \
    --volume="$(pwd):/go/src/github.com/ezanmoto/hello" \
    'ezanmoto/hello' \
    bash
```

This starts a Bash session "in" the build environment, but with the project
directory bind-mounted within the container. This means that any changes made
inside the container are reflected locally, and vice-versa. This setup has
numerous advantages when used as part of the development loop:

* Assuming that the build pipeline uses the same build image, there is now
  almost total parity between the development environment and the build
  pipeline environment, meaning that there's less variability after a developer
  pushes changes. A developer can easily build locally, without creating new
  Docker images, in almost the same conditions as the build will occur in the
  build pipeline.

* A subtle benefit of the previous point is that developers will be using the
  same version of dependencies as the build pipeline. For example, a new team
  member may use Go 1.14 locally but the build pipeline might still be on Go
  1.12 for various reasons. New Go features will work locally but will break the
  build. Being able to run with the same versions of tools locally means that
  there is less chance of this occurring in practice.

* Again following on from the previous point, updates are effortless, and safe
  across projects. For example, the image for the build pipeline may get updated
  from Go 1.12 to 1.15. It can often be a daunting task to update local
  installs, especially if there isn't a simple mechanism for removing old
  versions. With a specially-defined build image, local software doesn't need to
  be updated, but developers can instead simply work in the new build
  environment without installing the build tools locally. This also means that
  issues won't arise when a developer is working on two projects at the same
  time that require different versions of the same dependencies.

* Developers don't have to install programs locally at all! As a somewhat
  extreme example, even though I work primarily in Go and Rust, I don't have
  them installed on my host. Instead, they're installed in my build images that
  I work in interactively. This also means that environments can be cleaned
  effortlessly after finishing a project - removing the build images for that
  project removes all the programming languages and tools that were being used
  for that project.

* Setting up the development environment for a new developer is now handled
  automatically by the `docker build` process. Developers that want to replicate
  the setup locally can follow the instructions defined in `build.Dockerfile`
  manually.

* Outside of aspects like bound directories, the build environment is decoupled
  from the host. This means that there's less risk of accidentally depending on
  things that are present in the host environment that aren't going to be
  present in the build pipeline. A simple example of this could be depending on
  Linux tools that are native to the Ubuntu development host when Debian is
  being used as the build environment.

Disadvantages
-------------

While the approach outlined above is my personal approach and preference for
managing Docker images in a project, there are some notable caveats to it:

* The presented approach depends on the use of bind-mounting volumes for the
  build environment. This can work well in practice when using Linux images on
  Linux hosts, but may be less practical on other platforms. Furthermore, build
  environments that nest Docker containers may encounter extra complexity with
  working with bind-mounted volumes, as paths are referenced relative to the
  host's filesystem.

* When working interactively in the build environment you may quickly
  realise that users that you have defined locally don't exist in the build
  environment. Furthermore, trying to map users between these environments isn't
  the most straightforward - for example, do you [do it at build
  time](https://jtreminio.com/blog/running-docker-containers-as-current-host-user/)
  or [at run
  time](https://jtreminio.com/blog/running-docker-containers-as-current-host-user/#so-run-as-your-local-user-right)?
  This is perhaps one of the trickier aspects of running builds in containers
  instead of images, and could be a big argument in favour of the image
  approach. This is because any required users are usually better-defined in the
  image approach, typically being set up using the likes of `adduser`/`useradd`
  at the start of the image definition.

* Some people may consider the bind-mount approach to be less "pure" because the
  container is exposed to the host, and may worry about the reproducibility of
  the setup, since reproducibility is one of the main benefits of Docker.
  However, the approach is no less reproducible than the approach that performs
  `COPY .  /src`, as the entire host context is copied into the image. With both
  approaches, it is the responsibility of the build pipeline to ensure that the
  environment is clean and set up for reproducible results.

* As mentioned in the previous section, this approach achieves almost total
  parity between the development environment and the build pipeline environment,
  but that doesn't mean that subtle differences can't emerge between the two.

  For example, I encountered an issue with this setup when using
  [Samson](https://github.com/zendesk/samson) for CI/CD. By default, Samson
  doesn't actually do a full clone of a repository when running a new
  build/deployment, but instead creates a new Git worktree using symbolic links.
  This meant that the Git repository mounted in the build environment was
  referencing a file on the host, which couldn't be resolved in the build
  environment. I wasn't using worktrees locally, so this issue wasn't occurring
  in my local environment.

  The resolution was straightforward, but less than ideal: to force a full
  checkout for projects that needed it. Still, it highlights the fact that
  differences between the local environment and the build pipeline can still
  manifest with this approach, and special attention should be made when working
  with symbolic links in particular.

Conclusion
----------

Building code in Docker containers using `Docker run` is generally faster, more
space-conserving and more amenable to debugging than building code as part of a
`docker build`. Separating the build environment definition from build
instructions also allows for greater parity between the development environment
and the build pipeline, and allows for easier management of project
dependencies.
