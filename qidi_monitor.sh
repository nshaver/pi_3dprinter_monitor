#!/bin/bash
# Usage: ./monitor.sh <port> <api_key> <label>
PORT=qidi
KEY=4608BAD10621436C9559D698B0ED19AC

format_time() {
    local T=$1
    # Check if T is a numeric integer and > 0
    if [[ "$T" =~ ^[0-9]+$ ]] && [ "$T" -gt 0 ]; then
        printf '%02d:%02d:%02d\n' $((T/3600)) $((T%3600/60)) $((T%60))
    else
        echo "00:00:00"
    fi
}

while true; do
    # Pull Data with a 2-second timeout to prevent hanging
    P_DATA=$(curl -s -m 2 -H "X-Api-Key: $KEY" http://127.0.0.1/$PORT/api/printer)
    J_DATA=$(curl -s -m 2 -H "X-Api-Key: $KEY" http://127.0.0.1/$PORT/api/job)
    
    # Get the filename and default to "None" if nothing is printing
    FILE_NAME=$(echo "$J_DATA" | jq -r '.job.file.name // "None"')

    # Truncate to 25 characters so it doesn't break the layout
    if [ ${#FILE_NAME} -gt 25 ]; then
        FILE_NAME="${FILE_NAME:0:22}..."
    fi

    # Extract values and strip decimals immediately using cut
    STATE=$(echo "$P_DATA" | jq -r '.state.text // "Offline"')
    T0_ACT=$(echo "$P_DATA" | jq -r '.temperature.tool0.actual // 0' | cut -d. -f1)
    T1_ACT=$(echo "$P_DATA" | jq -r '.temperature.tool1.actual // 0' | cut -d. -f1)
    T0_TAR=$(echo $P_DATA | jq -r '.temperature.tool0.target // 0')
    T1_TAR=$(echo $P_DATA | jq -r '.temperature.tool1.target // 0')
    BED_ACT=$(echo "$P_DATA" | jq -r '.temperature.bed.actual // 0' | cut -d. -f1)
    BED_TAR=$(echo $P_DATA | jq -r '.temperature.bed.target // 0')
    
    # Handle Progress (convert float to integer safely)
    PROG_RAW=$(echo "$J_DATA" | jq -r '.progress.completion // 0')
    PROG=$(printf "%.0f" "$PROG_RAW" 2>/dev/null || echo 0)
    
    # Handle Time Remaining
    SECONDS_LEFT=$(echo "$J_DATA" | jq -r '.progress.printTimeLeft // 0' | cut -d. -f1)
    # Ensure SECONDS_LEFT is a pure number for the math function
    [[ "$SECONDS_LEFT" == "null" || -z "$SECONDS_LEFT" ]] && SECONDS_LEFT=0
    SECONDS_DONE=$(echo "$J_DATA" | jq -r '.progress.printTime // 0' | cut -d. -f1)
    ETR=$(format_time "$SECONDS_LEFT")
    ELAPSED=$(format_time "$SECONDS_DONE")

    # clear
    # Use printf to "Home" the cursor instead of 'clear'
    printf "\033[H"

    echo -e "\e[1;34m=== $PORT ===\e[K"
    echo -e "Status:   \e[1;32m$STATE\e[K"
    echo -e "File:     \e[1;37m$FILE_NAME\e[K"
    echo -e "Tool 0:   $T0_ACT°C / $T0_TAR°C\e[K"
    # Show Tool 1 only if it's not 0, or keep it for the Qidi
    echo -e "Tool 1:   $T1_ACT°C / $T1_TAR°C\e[K"
    echo -e "Bed:      $BED_ACT°C / $BED_TAR°C\e[K"
    echo -e "Elapsed:   \e[1;36m$ELAPSED\e[K"
    echo -e "Remaining: \e[1;35m$ETR\e[K"
    
    # Progress Bar Math
    BAR_SIZE=20
    # Ensure PROG is within 0-100 for the bar calculation
    SAFE_PROG=$(( PROG > 100 ? 100 : PROG ))
    FILLED=$(( SAFE_PROG * BAR_SIZE / 100 ))
    UNFILLED=$(( BAR_SIZE - FILLED ))
    BAR=$(printf "%${FILLED}s" | tr ' ' '#')$(printf "%${UNFILLED}s" | tr ' ' '-')
    echo -e "Progress: [\e[1;33m$BAR\e[0m] $PROG%\e[K"
    
    echo "Last Sync: $(date +%H:%M:%S)"
    echo -ne "\e[J"
    
    sleep 2
done
