<!--markdownlint-disable md013-->

# ziggymirror

this is a super simple zig mirror written in bash. the core simply mirrors the files and
you may use any http server of your liking to serve the tarballs. by default, its busybox httpd.

its recommended to use a reverse proxy, or heck even serve it yourself. set `PORT` to an empty string
to disable `httpd` but keep the sync daemon to run.

## configuration

configuration is done via environment variables

| variable                     | default                                                    | meaning                                                    |
| ---------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------- |
| `PORT`                       | `80`                                                       | port to serve the static files using httpd                 |
| `TEMP_DIR`                   | `/tmp/zigtemp`                                             | directory to store temp files like in-progress downloads   |
| `HTTP_DIR`                   | `/srv/http`                                                | directory to store final tarballs, minisig and other files |
| `DOWNLOAD_CONCURRENCY`       | `4`                                                        | number of downloads to run concurrently                    |
| `SYNC_INTERVAL`              | `86400`                                                    | time in seconds to sync updates from upstream              |
| `COMMUNITY_MIRRORS_CUSTOM`   | ``                                                         | override file path to use for community mirrors            |
| `SYNC_MASTER`                | ``                                                         | if set, master branch will also be downloaded              |
| `DOWNLOAD_INDEX`             | `https://ziglang.org/download/index.json`                  | -                                                          |
| `COMMUNITY_MIRRORS_URL`      | `https://ziglang.org/download/community-mirrors.txt`       | - used for initial seeding and on sync to update           |
| `COMMUNITY_MIRRORS_FALLBACK` | `/src/community-mirrors.txt`                               | - seeded from `COMMUNITY_MIRRORS_URL` on build             |
| `AUTOMATION_SOURCE`          | `github-dragsbruh-ziggymirror`                             | -                                                          |
| `MINISIGN_PUBKEY`            | `RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U` | -                                                          |

## notes

- on build, default for `COMMUNITY_MIRRORS_FALLBACK` file is seeded from official community mirrors.
- vars marked with `-` are recommended to be left empty unless you know what youre doing.
- files once moved to `HTTP_DIR` are neither modified or removed, this includes builds from master (if `SYNC_MASTER` is set).
  but they sure are checked to decide if we should redownload. the only exception is `index.json` and
  `community-mirrors.txt` which are updated. if `SYNC_MASTER` is unset, master branch will not be downloaded.
- `community-mirrors.txt` in `HTTP_DIR` stays independent of `COMMUNITY_MIRRORS_CUSTOM` and is updated from
  `COMMUNITY_MIRRORS_URL`, or seeded initially if doesnt exist from `COMMUNITY_MIRRORS_FALLBACK`
- all tarballs specified in `DOWNLOAD_INDEX` are downloaded. this includes ancient versions and the latest nightly release.
