#!/usr/bin/env bash

set -euo pipefail

print_usage() {
    echo "Usage: run-niri.sh [OPTIONS] -- <COMMAND>"
    echo "
Wrapper script to launch or focus an application."
    echo "
IMPORTANT: Separate run-niri.sh options from the command to be run with '--'."
    echo "
Options:"
    echo "  -c, --class <app_id>  Specify the window class (app_id) to search for."
    echo "                        Overrides auto-detection."
    echo "  -m, --move            If the window exists, move it to the current workspace"
    echo "                        before focusing."
    echo "  -s, --switch          If multiple windows exist, switch focus between them."
    echo "  -k, --kill            If a window exists in the current workspace, close it instead."
    echo "  -w, --workspace       Only consider existing windows in the current workspace."
    echo "  -n, --no-launch       Do not launch the application if no window is found."
    echo "  -t, --title <string>  Search for a window by its title instead of app_id."
    echo "  -h, --help            Show this help message."
    echo "
Example (foot terminal):"
    echo "  run-niri.sh -m -- foot --app-id 'ranger' -e ranger"
    echo "  (This will auto-detect 'ranger' as the class from the --app-id flag)"
    echo "
Example (manual class):"
    echo "  run-niri.sh -c com.company.App -- /opt/company/app --some-flag"
}

CLASS_OVERRIDE=""
MOVE_TO_ME=false
SWITCH_WINDOWS=false
KILL_FOCUSED=false
NO_LAUNCH=false
TITLE_SEARCH=""
SAME_WORKSPACE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    -c | --class)
        if [ -z "$2" ]; then
            echo "Error: --class requires an argument." >&2
            exit 1
        fi
        CLASS_OVERRIDE="$2"
        shift 2
        ;;
    -m | --move)
        MOVE_TO_ME=true
        shift
        ;;
    -s | --switch)
        SWITCH_WINDOWS=true
        shift
        ;;
    -k | --kill)
        KILL_FOCUSED=true
        shift
        ;;
    -n | --no-launch)
        NO_LAUNCH=true
        shift
        ;;
    -w | --workspace)
        SAME_WORKSPACE=true
        shift
        ;;
    -t | --title)
        if [ -z "$2" ]; then
            echo "Error: --title requires an argument." >&2
            exit 1
        fi
        TITLE_SEARCH="$2"
        shift 2
        ;;
    -h | --help)
        print_usage
        exit 0
        ;;
    --)
        shift # Consume the '--'
        break # Stop option parsing
        ;;
    -*)
        echo "Unknown option: $1" >&2
        print_usage
        exit 1
        ;;
    *)
        break
        ;;
    esac
done

if [ $# -eq 0 ]; then
    echo "Error: Missing command." >&2
    print_usage
    exit 1
fi
COMMAND_TO_RUN=("$@")
if [ -n "$TITLE_SEARCH" ]; then
    WINDOWS_DATA=$(niri msg --json windows | jq -c --arg query "$TITLE_SEARCH" \
        '[.[] | select(.title and (.title | test($query; "i")))]')
else
    SEARCH_CLASS=""
    if [ -n "$CLASS_OVERRIDE" ]; then
        SEARCH_CLASS="$CLASS_OVERRIDE"
    else
        for i in "${!COMMAND_TO_RUN[@]}"; do
            arg="${COMMAND_TO_RUN[$i]}"
            if [[ "$arg" == --app-id=* || "$arg" == --class=* ]]; then
                SEARCH_CLASS="${arg#*=}"
                break
            elif [[ "$arg" == "--app-id" || "$arg" == "--class" ]]; then
                next_index=$((i + 1))
                if [[ $next_index -lt ${#COMMAND_TO_RUN[@]} ]]; then
                    SEARCH_CLASS="${COMMAND_TO_RUN[$next_index]}"
                    break
                fi
            fi
        done
    fi

    if [ -z "$SEARCH_CLASS" ]; then
        SEARCH_CLASS=$(basename "${COMMAND_TO_RUN[0]}")
    fi

    if [ "$SAME_WORKSPACE" = true ]; then
        FOCUSED_WORKSPACE=$(niri msg -j workspaces | jq -c '.[] |select(.is_focused) | .id')
        WINDOWS_DATA=$(niri msg --json windows | jq -c --arg query "$SEARCH_CLASS" --arg workspace $FOCUSED_WORKSPACE \
            '[.[] | select(.app_id and .workspace_id==($workspace|tonumber) and (.app_id | test($query; "i")))]')
    else
        WINDOWS_DATA=$(niri msg --json windows | jq -c --arg query "$SEARCH_CLASS" \
            '[.[] | select(.app_id and (.app_id | test($query; "i")))]')
    fi
fi

mapfile -t WINDOW_IDS < <(echo "$WINDOWS_DATA" | jq -r '.[].id')

if [ ${#WINDOW_IDS[@]} -eq 0 ]; then
    if [ "$NO_LAUNCH" = true ]; then
        exit 0
    else
        nohup "${COMMAND_TO_RUN[@]}" >/dev/null 2>&1 &
    fi
else
    TARGET_WINDOW_ID=""

    # If kill mode is enabled, check if any matching window exists in current workspace
    if [ "$KILL_FOCUSED" = true ]; then
        FOCUSED_WORKSPACE=$(niri msg -j workspaces | jq -c '.[] |select(.is_focused) | .id')

        if [ -n "$TITLE_SEARCH" ]; then
            WORKSPACE_WINDOWS=$(niri msg --json windows | jq -c --arg query "$TITLE_SEARCH" --arg workspace "$FOCUSED_WORKSPACE" \
                '[.[] | select(.title and .workspace_id==($workspace|tonumber) and (.title | test($query; "i")))]')
        else
            WORKSPACE_WINDOWS=$(niri msg --json windows | jq -c --arg query "$SEARCH_CLASS" --arg workspace "$FOCUSED_WORKSPACE" \
                '[.[] | select(.app_id and .workspace_id==($workspace|tonumber) and (.app_id | test($query; "i")))]')
        fi

        WORKSPACE_WINDOW_IDS=($(echo "$WORKSPACE_WINDOWS" | jq -r '.[].id'))

        if [ ${#WORKSPACE_WINDOW_IDS[@]} -gt 0 ]; then
            # Close the first matching window in current workspace
            niri msg action close-window --id "${WORKSPACE_WINDOW_IDS[0]}"
            exit 0
        fi
    fi

    if [ "$SWITCH_WINDOWS" = true ] && [ ${#WINDOW_IDS[@]} -gt 1 ]; then
        FOCUSED_ID=$(echo "$WINDOWS_DATA" | jq -r '.[] | select(.is_focused) | .id')

        CURRENT_INDEX=-1
        for i in "${!WINDOW_IDS[@]}"; do
            if [[ "${WINDOW_IDS[$i]}" == "$FOCUSED_ID" ]]; then
                CURRENT_INDEX=$i
                break
            fi
        done

        NEXT_INDEX=$(((CURRENT_INDEX + 1) % ${#WINDOW_IDS[@]}))
        TARGET_WINDOW_ID="${WINDOW_IDS[$NEXT_INDEX]}"
    else
        TARGET_WINDOW_ID="${WINDOW_IDS[0]}"
    fi

    if [ "$MOVE_TO_ME" = true ]; then
        ACTIVE_WORKSPACE=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused==true) | .id')
        niri msg action move-window-to-workspace --window-id "$TARGET_WINDOW_ID" "$ACTIVE_WORKSPACE"
    fi

    niri msg action focus-window --id "$TARGET_WINDOW_ID"
fi
