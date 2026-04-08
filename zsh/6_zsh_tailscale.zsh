alias tsdown="tailscale down"

tsup() {
    tailscale up --accept-routes
    tstime
}

# Print time remaining until key expiry
tstime() {
    local ts_status=$(tailscale status --json)
    local expiry_time=$(echo "$ts_status" | jq '.Self.KeyExpiry' | tr -d '"')
    local expiry_time_utc=$(date -ujf '%Y-%m-%dT%H:%M:%SZ' "$expiry_time" "+%s" )
    local current_time_utc=$(date "+%s")

    local remaining_time=$((expiry_time_utc - current_time_utc))
    local hours=$((remaining_time / 3600))
    local minutes=$(((remaining_time % 3600) / 60))
    local seconds=$((remaining_time % 60))
    echo Device Key Expires in: "${hours}h ${minutes}m ${seconds}s"
}

# Tailscale Reauthenticate
tsra() {
    tailscale up --force-reauth --accept-routes
    echo "Device Key Expires in: 24h 0m 0s"
}
