#!/bin/bash

set -euo pipefail

COMMUNITY_MIRRORS_FILE=$HTTP_DIR/community-mirrors.txt
INDEX_JSON_FILE=$HTTP_DIR/index.json
INDEX_HTML_FILE=$HTTP_DIR/index.html

mkdir -p "$HTTP_DIR"
mkdir -p "$TEMP_DIR"

community_mirrors_current=$TEMP_DIR/$(basename "$COMMUNITY_MIRRORS_FILE")
if [ -n "$COMMUNITY_MIRRORS_CUSTOM" ]; then
  echo "warning: using custom community mirrors file"
  community_mirrors_current=$COMMUNITY_MIRRORS_CUSTOM
else
  echo "info: syncing community mirrors"
  {
    wget -q -O "$community_mirrors_current" "$COMMUNITY_MIRRORS_URL"
    cp "$community_mirrors_current" "$COMMUNITY_MIRRORS_FILE"
  } || {
    echo "error: failed to download new community mirrors file"
    if [ -f "$COMMUNITY_MIRRORS_FILE" ]; then
      echo "warning: did not update community mirrors file"
    else
      echo "warning: using fallback community mirrors file"
      cp "$COMMUNITY_MIRRORS_FALLBACK" "$COMMUNITY_MIRRORS_FILE"
      cp "$COMMUNITY_MIRRORS_FALLBACK" "$community_mirrors_current"
    fi
  }
fi

echo "info: fetching download index"
{
  temp_index=$TEMP_DIR/index.json
  wget -q -O "$temp_index" "$DOWNLOAD_INDEX"
  mv "$temp_index" "$INDEX_JSON_FILE"
} || {
  echo "error: failed to get download index"
  exit 1
}

echo "info: generating index.html template"
INDEX_JSON_FILE=${INDEX_JSON_FILE} /src/template.sh > "$INDEX_HTML_FILE"

download_tarball() {
  local tarball_name=$1
  local shasum=$2

  local found=0
  while read -r mirror_root; do
    local url_tarball=$mirror_root/$tarball_name
    local url_minisign="$mirror_root/$tarball_name.minisig?source=$AUTOMATION_SOURCE"

    local out_tarball=$HTTP_DIR/$tarball_name
    local out_minisign=$HTTP_DIR/"$tarball_name".minisig

    local temp_tarball=$TEMP_DIR/$tarball_name
    local temp_minisign=$TEMP_DIR/"$tarball_name".minisig

    if [ ! -f "$out_tarball" ]; then
      echo "info: fetching tarball '$tarball_name' from mirror '$mirror_root'"
      wget -q -O "$temp_tarball" "$url_tarball" || {
        echo "error: failed to download tarball '$tarball_name' from mirror '$mirror_root'"
        continue
      }

      echo "info: verifying sha sum for '$tarball_name'"
      echo "$shasum  $temp_tarball" | sha256sum -c - || {
        echo "error: failed to verify sha sum for '$tarball_name' from mirror '$mirror_root'"
        continue
      }

      echo "info: fetching tarball minisig for '$tarball_name'"
      wget -q -O "$temp_minisign" "$url_minisign" || {
        echo "error: failed to download minisign for tarball '$tarball_name' from mirror '$mirror_root'"
        continue
      }

      echo "info: verifying minisign for '$tarball_name'"
      printf '%s\n%s\n' 'untrusted comment: minisign public key' "$MINISIGN_PUBKEY" | minisign -Vm "$temp_tarball" -x "$temp_minisign" -p /dev/stdin || {
        echo "error: could not verify minisign for tarball '$tarball_name' from mirror '$mirror_root'"
        continue
      }

      mv "$temp_tarball" "$out_tarball"
      mv "$temp_minisign" "$out_minisign"

      found=1
      echo "info: completed download of '$tarball_name' from '$mirror_root'"
      break
    else
      echo "info: tarball '$tarball_name' already exists, skipping"
      found=1
      break
    fi
  done < <(shuf "$community_mirrors_current")

  [ "$found" -eq 1 ] || {
    echo "error: no valid mirror found for $tarball_name"
  }
}

echo "info: parsing download index"
job_list=$(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$INDEX_JSON_FILE")
readarray -t jobs_array <<< "$job_list"

echo "info: downloading tarballs"
for line in "${jobs_array[@]}"; do
  IFS='=' read -r version value <<< "$line"
  IFS='=' read -r shasum source_tarball <<< "$(jq -r 'to_entries[] | select(.value | type == "object") | .value | "\(.shasum)=\(.tarball)"' <<< "$value")"

  if [ ! -n "$SYNC_MASTER" ] && [ "$version" = "master" ]; then
    continue
  fi

  tarball_name=$(basename "$source_tarball")

  while [ "$(jobs -rp | wc -l)" -ge "$DOWNLOAD_CONCURRENCY" ]; do
      sleep 0.1
  done

  download_tarball "$tarball_name" "$shasum" &
done

wait
echo "info: download jobs completed"
