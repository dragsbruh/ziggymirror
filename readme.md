<!--markdownlint-disable md013-->

# ziggymirror

this is a super simple zig mirror written in bash. the core simply mirrors the files and
you may use any http server of your liking to serve the tarballs. by default, it is busybox httpd.

i recommended you use a reverse proxy. if you want to use your own http server, set `PORT` to an empty string
to disable `httpd` but keep the download sync daemon to run.

## features

- sync master versions
- cleanup old master versions
- nice env var based config
- concurrent downloads
- simple `index.html` template generator

## usage

### running via docker compose

you can use [compose.yml](./compose.yml) (remember to check if config is to your liking first)

```sh
docker compose up -d
```

### running via docker

i recommend compose over this.

```sh
docker pull ghcr.io/dragsbruh/ziggymirror:latest
docker run -v /srv/http:/srv/http -d ghcr.io/dragsbruh/ziggymirror:latest
```

### running via bash

this is not the recommended way but somewhat works.
we do not cover http server here, only the download daemon.

you will need: `bash`, `jq`, `minisign`, and `wget`

first, clone this repository and `cd` into it. then:

```sh
#!/bin/bash

cp .env.example .env

# change your .env to your liking

source .env

mkdir -p $(dirname "${COMMUNITY_MIRRORS_FALLBACK}")
wget -O "${COMMUNITY_MIRRORS_FALLBACK}" "$COMMUNITY_MIRRORS_URL"

./run.sh
```

## configuration

configuration is done via environment variables

| variable                     | default                                                    | meaning                                                        |
| ---------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------- |
| `PORT`                       | `80`                                                       | port to serve the static files using httpd                     |
| `TEMP_DIR`                   | `/tmp/zigtemp`                                             | directory to store temp files like in-progress downloads       |
| `HTTP_DIR`                   | `/srv/http`                                                | directory to store final tarballs, minisig and other files     |
| `DOWNLOAD_CONCURRENCY`       | `4`                                                        | number of downloads to run concurrently                        |
| `SYNC_INTERVAL`              | `86400`                                                    | time in seconds to sync updates from upstream                  |
| `COMMUNITY_MIRRORS_CUSTOM`   | -                                                          | override file path to use for community mirrors                |
| `SYNC_MASTER`                | -                                                          | if set, master branch will also be downloaded                  |
| `CLEANUP_OLD`                | -                                                          | if set, versions missing from `index.json` are deleted on sync |
| `TEMPLATE_SCRIPT`            | `/src/template.sh`                                         | bash script that prints `index.html` to stdout                 |
| `DOWNLOAD_INDEX`             | `https://ziglang.org/download/index.json`                  | !                                                              |
| `SYNC_SCRIPT`                | `/src/sync.sh`                                             | ! only here for dev environment                                |
| `COMMUNITY_MIRRORS_URL`      | `https://ziglang.org/download/community-mirrors.txt`       | ! used for initial seeding and on sync to update               |
| `COMMUNITY_MIRRORS_FALLBACK` | `/src/community-mirrors.txt`                               | ! seeded from `COMMUNITY_MIRRORS_URL` on build                 |
| `AUTOMATION_SOURCE`          | `github-dragsbruh-ziggymirror`                             | !                                                              |
| `MINISIGN_PUBKEY`            | `RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U` | !                                                              |

## customization

`index.html` is generated via a bash script that writes the template to stdout. the path to download index file
is passed via `INDEX_JSON_FILE` environment variable and you can use `jq` to generate the html file you want.
the path to template file must be provided via `TEMPLATE_SCRIPT` environment variable and must be an executable.

see the [default](./template.sh) template for example.

## notes

- if you encounter any errors or have any improvements, please open an issue. it is appreciated.
- on build, default for `COMMUNITY_MIRRORS_FALLBACK` file is seeded from official community mirrors.
- vars marked with `!` are recommended to be left empty unless you know what youre doing.
- tagged versions once moved to `HTTP_DIR` are neither modified or removed. and:
  - `index.json` and `community-mirrors.txt` are updated.
  - unless `CLEANUP_OLD` is set, no tarball is ever removed,
    as this flag removes tarballs/minisigs that no longer exist in `index.json`
  - if `SYNC_MASTER` is unset, master branch will not be downloaded.
- `community-mirrors.txt` in `HTTP_DIR` stays independent of `COMMUNITY_MIRRORS_CUSTOM` and is updated from
  `COMMUNITY_MIRRORS_URL`, or seeded initially if doesnt exist from `COMMUNITY_MIRRORS_FALLBACK`
- all tarballs specified in `DOWNLOAD_INDEX` are downloaded. this includes ancient versions and the latest nightly release.
- if `SYNC_MASTER` is enabled and `CLEANUP_OLD` is not, the older master versions are not deleted but also
  not shown in `index.json` or in the ui. i plan to change this later. therefore i recommend you set them both
  together or disable together. `CLEANUP_OLD` is redundant if `SYNC_MASTER` is unset.
