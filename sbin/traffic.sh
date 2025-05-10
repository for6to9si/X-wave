#!/opt/bin/sh

_APISERVER=127.0.0.1:8080
_XRAY=/opt/sbin/xray
CSV_FILE="/opt/var/log/xwave/xray_stats.csv"
export PATH=/opt/bin:/opt/sbin:/usr/bin:/bin:/sbin:/usr/sbin

# CMD="/opt/sbin/traffic.sh >> /opt/tmp/traffic.log 2>&1"
# crontab -l 2>/dev/null | grep -F "$CMD" >/dev/null || \
#   (crontab -l 2>/dev/null; echo "*/5 * * * * $CMD") | crontab -

#(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/sbin/traffic.sh >> /opt/tmp/traffic.log 2>&1") | crontab -


#crontab -l

# тот же apidata, но value в байтах (число без единиц)
apidata () {
#    echo "tttt" >&2
    ARGS=
    [ "$1" = "reset" ] && ARGS="-reset=true"
    $_XRAY api statsquery --server=$_APISERVER $ARGS \
    | awk '{
        if (match($1, /"name":/)) {
            f=1; gsub(/^"|",?$/, "", $2);
            split($2, p,  ">>>");
            key = p[1] ":" p[2] "->" p[4];
        }
        else if (match($1, /"value":/) && f) {
            f=0;
            val=$2+0;
            printf "%s\t%s\n", key, val;
        }
        else if (match($0, /}/) && f) {
            f=0;
            printf "%s\t0\n", key;
        }
    }'
}

# Список полей в нужном порядке
FIELDS="inbound:tproxy->down inbound:socks-in->up inbound:socks-in->down inbound:redirect->up inbound:redirect->down inbound:api->up inbound:tproxy->up inbound:api->down outbound:vless-udp->up outbound:vless-udp->down outbound:vless-german->up outbound:vless-reality->down outbound:vless-german->down outbound:direct->up outbound:direct->down outbound:vless-reality->up outbound:block->up outbound:block->down outbound:dns-out->up outbound:dns-out->down"
#FIELDS="outbound"

# Печать на экран (ваша текущая логика)
print_sum() {
    DATA="$1"; PREFIX="$2"
    echo "$DATA" | grep "^${PREFIX}" | sort -r | awk '
        /->up/{us+=$2}
        /->down/{ds+=$2}
        END {
          printf "SUM->up:\t%.0f\nSUM->down:\t%.0f\nSUM->TOTAL:\t%.0f\n",us,ds,us+ds
        }' \
      | numfmt --field=2 --suffix=B --to=iec | column -t
}

#apidata

DATA=$(apidata $1)

echo "------------Inbound----------"
print_sum "$DATA" "inbound"
echo "-----------------------------"
echo "------------Outbound----------"
print_sum "$DATA" "outbound"
echo "-----------------------------"
echo
echo "-------------User------------"
print_sum "$DATA" "user"
echo "-----------------------------"

# ———— НОВОЕ: собираем и дописываем CSV ————

# 1) Заголовок, если нужно
if [ ! -f "$CSV_FILE" ]; then
  printf "timestamp" > "$CSV_FILE"
  printf ",top xray" >> "$CSV_FILE"
  for fld in $FIELDS; do
    printf ",%s" "$fld" >> "$CSV_FILE"
  done
  printf "\n" >> "$CSV_FILE"
fi

# 2) Собираем одну строку: timestamp + значения в байтах
TS=$(date -Iseconds)
printf "%s" "$TS" >> "$CSV_FILE"
_TOP=$(top -n 1 | grep "xray run" | grep -v grep | sed -E 's/([0-9]+m)([0-9]+\.[0-9]+)/\1 \2/' | awk '{cpu += $8} END {print cpu}' || echo 'xray not running')
printf ",%s" "$_TOP" >> "$CSV_FILE"
for fld in $FIELDS; do
  # ищем exact match "fld\t<number>"
  val=$(printf "%s\n" "$DATA" | grep "^${fld}" | cut -f2)

  #val=$(echo "$DATA" | grep "^${fld}" | cut -f2)
  #echo $val
  [ -z "$val" ] && val=0
  val=$(awk -v v="$val" 'BEGIN { printf "%.2fMiB", v / (1024 * 1024) }')
  printf ",%s" "$val" >> "$CSV_FILE"
done
printf "\n" >> "$CSV_FILE"
