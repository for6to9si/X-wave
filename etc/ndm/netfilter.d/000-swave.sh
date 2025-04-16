#!/bin/sh

# Путь к JSON-файлу с настройками
SETTING="/opt/etc/swave/settings.json"

get_clean_json() {
  awk '
  BEGIN { in_string = 0 }
  {
    line = $0
    result = ""
    for (i = 1; i <= length(line); i++) {
      char = substr(line, i, 1)
      next_char = substr(line, i+1, 1)
      if (char == "\"" && prev != "\\") {
        in_string = !in_string
      }
      if (!in_string && char == "/" && next_char == "/") {
        break
      }
      result = result char
      prev = char
    }
    print result
  }' "$1"
}

restart_script() {
    "$0" "$@"
    exit $?
}

js_SETTING=$(get_clean_json "$SETTING" | jq -c '.' 2>/dev/null)


echo "$js_SETTING"

CMD=$(echo "$js_SETTING" | jq -r '.client.name')

if pgrep -f "${CMD} run" > /dev/null
then

  echo "test"
else

    sleep 5

    restart_script "$@"
fi
