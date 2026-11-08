#!/bin/bash
set -u

METRICS_DIR="/var/lib/prometheus/node-exporter"
TMP_FILE="$METRICS_DIR/dayz_service.prom.tmp"
OUT_FILE="$METRICS_DIR/dayz_service.prom"


STATE=$(systemctl is-active dayz.service || true)
PID=$(systemctl show dayz.service -p MainPID --value)
STATE_DIR="/var/lib/dayz-metrics"
PID_FILE="$STATE_DIR/last_pid"
RESTARTS_FILE="$STATE_DIR/restarts"

RESTARTS=0
LAST_PID=""

if [ -f "$RESTARTS_FILE" ]; then
    RESTARTS=$(cat "$RESTARTS_FILE")
fi

if [ -f "$PID_FILE" ]; then
    LAST_PID=$(cat "$PID_FILE")
fi

if [[ "$PID" =~ ^[1-9][0-9]*$ ]] && [ -r "/proc/$PID/stat" ]; then
    if [ "$PID" != "$LAST_PID" ]; then
        if [ -n "$LAST_PID" ]; then
            RESTARTS=$((RESTARTS + 1))
        fi
        echo "$PID" > "$PID_FILE"
        echo "$RESTARTS" > "$RESTARTS_FILE"
    fi
fi



SERVICE_UP=0
PROCESS_UP=0
CPU_SECONDS=0
RSS_BYTES=0
START_TIME=0
UPTIME_SECONDS=0

if [ "$STATE" = "active" ]; then
    SERVICE_UP=1
fi

if [[ "$PID" =~ ^[1-9][0-9]*$ ]] && [ -r "/proc/$PID/stat" ]; then
    STAT_LINE=$(cat "/proc/$PID/stat")
    STAT_REST=${STAT_LINE##*) }
    read -r -a FIELDS <<< "$STAT_REST"

    UTIME=${FIELDS[11]}
    STIME=${FIELDS[12]}
    START_TICKS=${FIELDS[19]}

    HZ=$(getconf CLK_TCK)

    CPU_SECONDS=$(awk -v ticks="$((UTIME + STIME))" \
        -v hz="$HZ" 'BEGIN {printf "%.6f", ticks/hz}')

    RSS_KB=$(awk '/^VmRSS:/ {print $2}' "/proc/$PID/status")
    RSS_BYTES=$((RSS_KB * 1024))

    BOOT_TIME=$(awk '/^btime / {print $2}' /proc/stat)

    START_TIME=$(awk -v boot="$BOOT_TIME" \
        -v ticks="$START_TICKS" \
        -v hz="$HZ" 'BEGIN {printf "%.6f", boot + ticks/hz}')

    NOW=$(date +%s)
    UPTIME_SECONDS=$(awk -v now="$NOW" \
        -v start="$START_TIME" \
        'BEGIN {printf "%.0f", now - start}')

    PROCESS_UP=1
fi

cat > "$TMP_FILE" <<EOF2
# HELP dayz_service_up Whether the DayZ systemd service is active.
# TYPE dayz_service_up gauge
dayz_service_up $SERVICE_UP
# HELP dayz_service_main_pid Main PID of the DayZ service.
# TYPE dayz_service_main_pid gauge
dayz_service_main_pid $PID
# HELP dayz_process_up Whether the DayZ process exists.
# TYPE dayz_process_up gauge
dayz_process_up $PROCESS_UP
# HELP dayz_process_cpu_seconds_total Total CPU time used by DayZ process.
# TYPE dayz_process_cpu_seconds_total counter
dayz_process_cpu_seconds_total $CPU_SECONDS
# HELP dayz_process_memory_rss_bytes Resident memory used by DayZ process.
# TYPE dayz_process_memory_rss_bytes gauge
dayz_process_memory_rss_bytes $RSS_BYTES
# HELP dayz_process_start_time_seconds Unix timestamp when DayZ process started.
# TYPE dayz_process_start_time_seconds gauge
dayz_process_start_time_seconds $START_TIME
# HELP dayz_process_uptime_seconds Seconds since DayZ process started.
# TYPE dayz_process_uptime_seconds gauge
dayz_process_uptime_seconds $UPTIME_SECONDS
# HELP dayz_process_restarts_total Total number of detected DayZ process restarts.
# TYPE dayz_process_restarts_total counter
dayz_process_restarts_total $RESTARTS
EOF2

chmod 0640 "$TMP_FILE"
chown root:prometheus "$TMP_FILE"
mv "$TMP_FILE" "$OUT_FILE"