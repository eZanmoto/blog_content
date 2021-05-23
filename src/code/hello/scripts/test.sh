# Copyright 2021 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

set -o errexit

proj='ezanmoto/hello'
build_img="$proj.build"
run_img="$proj"

main() {
    {
        bash scripts/markdownlint_rbuild.sh README.md

        # NOTE `bash scripts/markdownlint_rbuild.sh` must be run before this
        # command in order to ensure that the `ezanmoto/hello.markdownlint`
        # image exists.
        bash scripts/markdownlint.sh README.md
    }

    {
        bash scripts/with_build_env_basic.sh \
            bash -c '! (gofmt -s -d cmd | grep "") && touch target/test'

        ls -l target/test \
            | grep root

        bash scripts/with_build_env_dev.sh \
            bash -c '! (gofmt -s -d cmd | grep "") && rm target/test'

        bash scripts/with_build_env_user.sh \
            bash -c 'touch target/test'

        rm target/test

        bash scripts/with_build_env_go.sh \
            bash -c '! (gofmt -s -d cmd | grep "")'

        docker volume \
            rm \
            'ezanmoto.hello.tmp_cache' \
            'ezanmoto.hello.pkg_cache'
    }

    {
        bash scripts/docker_rbuild.sh \
            "$run_img" \
            'latest' \
            -f run.Dockerfile \
            .

        test_img
        trap '' EXIT RETURN
    }

    {
        bash scripts/build_img.sh

        test_img
        trap '' EXIT RETURN
    }

    {
        test_compose
        trap '' EXIT RETURN
    }
}

test_img() {
    docker network create hello_default \
        > /dev/null
    trap 'docker network rm hello_default' EXIT RETURN

    cont_id=$(
        docker run \
            --rm \
            --detach \
            --network=hello_default \
            --network-alias=hello \
            "$run_img"
    )
    trap "kill_cont $cont_id && docker network rm hello_default" EXIT RETURN

    ping_container 'http://hello:3000'
}

kill_cont() {
    cont_id="$1"

    docker logs "$cont_id" \
        | sed 's/^/[>] /'
    docker kill "$cont_id"
}

ping_container() {
    docker run \
        --rm \
        -it \
        --network=hello_default \
        "$build_img" \
        curl \
            --fail \
            --silent \
            http://hello:3000
}

test_compose() {
    {
        bash scripts/docker_compose_up_build.sh \
            --detach
        trap "docker-compose logs && docker-compose down" EXIT RETURN

        ping_container 'http://hello.seankelleher.local'
    }
}

main
