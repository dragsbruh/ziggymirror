#!/bin/bash

numfmt() {
  local n=$1
  local units=(B K M G)
  local i=0

  [[ -z $n || $n -lt 0 ]] && { echo "0 B"; return; }

  while (( n >= 1024 && i < ${#units[@]}-1 )); do
    n=$(( n / 1024 ))
    ((i++))
  done

  echo "$n ${units[i]}"
}

cat <<EOF
<html>
  <head>
    <title>ziggymirror</title>
  </head>
  <body>
    <h1>ziggymirror</h1>
    <a href="https://github.com/dragsbruh/ziggymirror" style="font-size: 16px;">source</a>
    <ul>
EOF

while IFS='=' read -r version releases date docs notes stdDocs; do
  if [ ! -n "$SYNC_MASTER" ] && [ "$version" = "master" ]; then
    continue
  fi

  cat <<EOF
      <li>
        <h2>$version</h2>
        <ul>
          <li>$date</li>
EOF
  if [ ! "$notes" = "null" ]; then
    echo "<li><a href=\"$notes\">release notes</a></li>"
  fi
  if [ ! "$docs" = "null" ]; then
    echo "<li><a href=\"$docs\">documentation</a></li>"
  fi
  if [ ! "$stdDocs" = "null" ]; then
    echo "<li><a href=\"$stdDocs\">standard library documentation</a></li>"
  fi

  echo "<li>releases<ul>"

  while IFS='=' read -r target tarball size; do
    echo "<li><a href=\"/$(basename "$tarball")\">$target</a> ($(numfmt "$size"))</li>"
  done < <(echo "$releases" | jq -r 'to_entries[] | select (.value | type == "object") | "\(.key)=\(.value.tarball)=\(.value.size)"' )

  echo "</ul></li>"

  cat <<EOF
        </ul>
      </li>
EOF
done < <(jq -r 'to_entries[] | "\(.key)=\(.value)=\(.value.date)=\(.value.docs)=\(.value.notes)=\(.value.stdDocs)"' "$INDEX_JSON_FILE")

cat <<EOF
    </ul>
  </body>
</html>
EOF
