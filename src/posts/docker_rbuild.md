---
title: Docker Build `--replace`
date: 2021-04-11
tags:
- devops
- docker
---

This article covers "docker build replace", a script that I use in projects that
contain Dockerfiles, which aims to help overcome some of the main drawbacks I
encounter when using Dockerfiles in a project.

The `docker build` command is great for helping to achieve reproducible builds
for projects, where in the past developers had to rely on setting up the correct
environment manually in order to get a successful build. One big drawback of
`docker build`, however, is that it can be very costly in terms of storage when
running it multiple times, as each run of the command will generally leave
unnamed images around.  Cleanup can be straightforward, but requires continual
pruning.

The need to remove unused images is particularly felt when trying to develop and
debug Dockerfiles. Trying to come up with a minimal set of instructions that
will allow you to run your processes the way that you want can require several
`docker build` runs, even after you've narrowed down the scope with an
interactive `docker run` session. Such a sequence may well require a few Docker
image purges over the course of a session as your disk is continually overbooked
by old and redundant images. This is compounded further if your Docker image
makes use of a command such as `COPY . /src`, where each change to your root
project will require a new image build.

This is where `docker build --replace` comes in, where Docker automatically
removes the old image with the same tag when a new copy is built, and skips the
build entirely if it's up-to-date. The only problem is that this flag doesn't
currently exist.

`docker_rbuild.sh`
------------------

I wrote `docker_rbuild.sh` ("Docker replace build") to approximate the idea of
`docker build --replace` by making use of the build cache:

```bash
!snippet code/hello/scripts/docker_rbuild.sh 5 26 qBe5zVAbhEreCGvw/UiCsxrdYfM=
```

This tags the current copy of the image so that it can be reused for caching
purposes, and then kicks off a new build. If the build was successful then the
"cache" version is removed, theoretically meaning that only the latest copy of
the image you're working on should be present in your system. If the build fails
then the old tag is restored. If there are no updates then the cached layers are
used to create a "new" image almost instantly to replace the old one.

With this, local images are automatically "pruned" as newer copies are produced,
saving time and disk space.

Idempotency
-----------

One benefit of `docker_rbuild.sh` is the fact that, now that `docker build`
isn't leaving redundant images around with each build, it is more practicable to
use it in scripts to rebuild our images before we run them. This is useful when
a project defines local images so that we can rebuild the image before it's
used, every time that it's used, so that we're always using the latest version
of the image without having to manually update it.

An example of where this can be convenient is when you want to use an external
program or project that uses a language that isn't supported by your project.
For example, the build process for this blog's content uses Node.js, but
consider the case where I wanted to use a Markdown linter defined in Ruby, such
as [Markdownlint](https://github.com/markdownlint/markdownlint). One option is
to add a Ruby installation directly to the definition of the build environment,
but this has a few disadvantages:

* It adds an installation for a full new language to the build environment just
  to support the running of one program.
* It isn't clear, at a glance, that Ruby is only being installed to support one
  tool, and to someone new to the project it can look like the project is a
  combined Node.js/Ruby project.
* The above point lends itself to using more Ruby gems "just because" it's
  available, meaning that removing the Ruby installation later becomes more
  difficult.

One way to work around this is to encapsulate the usage with a Dockerfile, like
`markdownlint.Dockerfile`, and a script that runs the tool:

`markdownlint.Dockerfile`:

```dockerfile
!snippet code/hello/markdownlint.Dockerfile 5 5 P+lH5j0SUce3cBFlsM5f1Gu1XGI=
```

`markdownlint.sh`:

```bash
!snippet code/hello/scripts/markdownlint.sh 5 16 dNnr7tu06sAgKUU9ZccjfJgYIv4=
```

This addresses some of the above issues:

* Ruby isn't installed directly into the build environment, meaning that the
  build environment is kept focused and lean.
* In `markdownlint.Dockerfile`, the Ruby installation is kept with the program
  that it's used to run, making the association clear.
* The entire Ruby installation can be removed easily by deleting
  `markdownlint.Dockerfile`. This can be useful if we decide to replace the tool
  with a different linter, like [this one written for
  Node.js](https://www.npmjs.com/package/markdownlint-cli). Another reason why
  we might remove `markdownlint.Dockerfile` is if the external project starts
  maintaining its own public Docker image that can be used instead of managing a
  local version.

Despite the benefits, there are two subtle issues with this setup. The first is
that `ezanmoto/blog_content.markdownlint` will need to be built somehow before
`markdownlint.sh` can be run, which may be a manual process, and it would also
be a surprising error to find out that an image is missing for a script.

The second issue is that if one developer builds the local image, and a second
developer updates the image definition, the first developer will need to rebuild
their copy of the local image before running `markdownlint.sh` again or risk
unexpected results.

We can solve both of these issues by running `docker_rbuild.sh` before
running `ezanmoto/blog_content.markdownlint`:

`markdownlint.sh`:

<!-- markdownlint-disable line-length -->
```bash
!snippet code/hello/scripts/markdownlint_rbuild.sh 15 12 czZUDPBvbIih+XmHhL1dPhRNrCY=
```
<!-- markdownlint-enable -->

This causes the image to be always be rebuilt before it's used, meaning that
we're always working with the latest version of the image, and this build step
will most often be skipped due to caching (though attention should be paid to
the commands used in the image build, as the use of commands like `COPY` can
limit the effectiveness of the cache).

Use With `docker-compose`
-------------------------

I find `docker-compose` particularly useful for modelling deployments. However,
like developing Docker images, getting the `docker-compose` environment correct
can require continual fine-tuning of Docker images, especially for defining
minimal environments. This can again result in lots of wasted space, especially
when used with `docker-compose up --build`.

With that in mind, I now remove the `build` property from services defined in
`docker-compose.yml`. This then requires the images to be built before
`docker-compose` is called, which I normally handle in a script that will build
all of the images used in the `docker-compose.yml` file before the file is
called:

`docker-compose.yml`:

```yaml
!snippet code/hello/docker-compose.yml 5 12 QCHF5t+ZtmBU5UB1JkmNPvUvaP0=
```

`scripts/docker_compose_up_build.sh`:

<!-- markdownlint-disable line-length -->
```bash
!snippet code/hello/scripts/docker_compose_up_build.sh 5 11 QsuxXO/EyeQHxOjpqhGpXiGRy6A=
```
<!-- markdownlint-enable -->

Conclusion
----------

Having an idempotent rebuild for Docker images means that it's more feasible to
rebuild before each run, much in the same way that some build tools (e.g.
`cargo`) update any changed dependencies before attempting to rebuild the
codebase. While Docker doesn't have native support for this at present, a script
that takes advantage of the cache can be used to simulate such behaviour.
