#!/bin/sh

# Путь к JSON-файлу с настройками
SETTING="/opt/etc/swave/settings.json"

# Если переменная не задана, используем /dev/null
LOG_FILE="${IP_RULES_LOG:-/dev/null}"

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
  exec /bin/sh "\$0" "\$@"
}

js_SETTING=$(get_clean_json "$SETTING" | jq -c '.' 2>/dev/null)

CMD=$(echo "$js_SETTING" | jq -r '.client.name')

logger -p notice -t "$CMD" "$js_SETTING"


if pgrep -f "${CMD} run" > /dev/null
then

# Если переменная не задана, используем /dev/null
LOG_FILE="${IP_RULES_LOG:-/dev/null}"

busybox ip -4 rule add fwmark 123 lookup 100 >>"$LOG_FILE" 2>&1

else

    sleep 5

    restart_script "$@"
fi

