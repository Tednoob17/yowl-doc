name: Chocolatine tester

on:
  push:
      branches-ignore: [ga-ignore-*]
  pull_request:
      branches-ignore: [ga-ignore-*]

env:
  MIRROR_URL: $Github_repo
  EXECUTABLES: 'my_binary'

jobs:

    coding-style:
        name: Run Banana
        runs-on: ubuntu-latest
        container:
            image: ghcr.io/epitech/coding-style-checker:latest

        steps:

            - name: Checkout my repo
              uses: actions/checkout@master

            - name: Run coding-style checker
              run: check.sh $(pwd) $(pwd)

            - name: Report banana output
              run: |
                NB_ERROR=$(cat coding-style-reports.log | wc -l)
                if [ $NB_ERROR -gt 0 ]; then
                    ERROR=$(cat coding-style-reports.log)
                    echo "::error title=$NB_ERROR errors found::$ERROR"
                    exit 1
                fi
                exit 0

    compile:
        runs-on: ubuntu-latest
        steps:

          - name: Checkout my repo
            uses: actions/checkout@master

          - name: Compile reposiory
            run: make

          - name: Check binary presence
            run: |
              if [! -f ./${{ env.EXECUTABLES }}]; then
                  echo "::error file=./${{ env.EXECUTABLES }}, title=Binary
                  Error::Binary not found"
                  exit 1
              fi
              exit 0

    run-tests:
        runs-on: ubuntu-latest
        name: Run Unit & Integration Tests
        container: epitechcontent/epitest-docker:latest
        needs: [compile, coding-style]

        steps:

            - name: Checkout my repo
              uses: actions/checkout@master

            - name: Compile tests binaries
              run: make compile_tests


    push_to_mirror:
      runs-on: ubuntu-latest
      name: push_to_mirror
      needs: [compile, coding-style, run-tests]
      if: github.event_name == 'push'

      steps:

          - name: Checkout GH repo
            uses: actions/checkout@master
            with:
              fetch-depth: 0

          - name: push_to_mirror
            uses: pixta-dev/repository-mirroring-action@v1
            with:
              target_repo_url: ${{ env.MIRROR_URL }}
              ssh_private_key: ${{ secrets.GIT_SSH_PRIVATE_KEY }}