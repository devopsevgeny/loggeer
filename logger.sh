#!/usr/bin/env bash

########################################
# Custom Bash Logger
#
# This logger script provides flexible logging to screen, file, and/or journal
# It supports multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL).
# It also supports verbose logging, file rotation, and customizable log formats.
#
# Usage: 
#   source /path/to/logger.sh
#   init_logger [-l <logfile>] [-v] [-f <logformat>] [-L <loglevel>]
#
# Functions:
#   init_logger          - Initializes the logger.
#   log_<level>          - Logs messages at specific levels (e.g., log_debug, log_info, log_error).
#   rotate_logs          - Handles log file rotation when the log size exceeds a set limit.
#   set_log_level        - Sets the current log level.
#   set_log_file         - Specifies the log file for logging.
#   set_log_format       - Specifies the log format.
#
# This script is designed to be sourced by other scripts.
#
########################################

# Log Levels
DEBUG=1
INFO=2
WARNING=3
ERROR=4
CRITICAL=5

# Default settings
LOG_LEVEL=$INFO
LOG_FILE=""
LOG_FORMAT="%d [%l] [%s] %m"
CONSOLE_LOG=true
FILE_LOG=false
VERBOSE=false
LOG_ROTATION_SIZE=1000000  # Rotate logs if size exceeds 1MB
LOG_ROTATION_COUNT=5       # Keep 5 rotated logs

# Set up file descriptor for verbose logging
exec 3>&1

# Get current date and time
get_date() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Format log message
format_log_message() {
    local level="$1"
    local message="$2"
    local script_name="${3:-unknown}"
    local current_date
    current_date=$(get_date)
    
    # Replace format placeholders
    local formatted_message="${LOG_FORMAT//%d/$current_date}"
    formatted_message="${formatted_message//%l/$level}"
    formatted_message="${formatted_message//%s/$script_name}"
    formatted_message="${formatted_message//%m/$message}"
    
    echo "$formatted_message"
}

# Initialize the logger
init_logger() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -l|--logfile)
                shift
                LOG_FILE="$1"
                FILE_LOG=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -L|--loglevel)
                shift
                LOG_LEVEL="$1"
                ;;
            -f|--logformat)
                shift
                LOG_FORMAT="$1"
                ;;
            *)
                echo "Unknown option $1"
                return 1
                ;;
        esac
        shift
    done
}

# Log a message at the specified level
log_message() {
    local level="$1"
    local level_value="$2"
    local message="$3"
    
    if [[ "$level_value" -ge "$LOG_LEVEL" ]]; then
        local formatted_message
        formatted_message=$(format_log_message "$level" "$message" "${BASH_SOURCE[1]}")
        
        # Log to console
        if [[ "$CONSOLE_LOG" == true ]]; then
            echo "$formatted_message" >&3
        fi
        
        # Log to file if enabled
        if [[ "$FILE_LOG" == true && -n "$LOG_FILE" ]]; then
            echo "$formatted_message" >> "$LOG_FILE"
        fi
    fi
}

# Rotate the log files if they exceed the specified size
rotate_logs() {
    local log_file="$1"
    local file_size
    file_size=$(stat -c %s "$log_file")
    
    if [[ "$file_size" -ge "$LOG_ROTATION_SIZE" ]]; then
        for ((i=LOG_ROTATION_COUNT; i>=0; i--)); do
            if [[ -f "$log_file.$i" ]]; then
                if [[ "$i" -eq "$LOG_ROTATION_COUNT" ]]; then
                    rm "$log_file.$i"
                else
                    mv "$log_file.$i" "$log_file.$((i+1))"
                fi
            fi
        done
        mv "$log_file" "$log_file.0"
        touch "$log_file"
    fi
}

# Set the log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
set_log_level() {
    local level="$1"
    case "$level" in
        DEBUG) LOG_LEVEL=$DEBUG ;;
        INFO) LOG_LEVEL=$INFO ;;
        WARNING) LOG_LEVEL=$WARNING ;;
        ERROR) LOG_LEVEL=$ERROR ;;
        CRITICAL) LOG_LEVEL=$CRITICAL ;;
        *) echo "Invalid log level: $level"; return 1 ;;
    esac
}

# Set the log file
set_log_file() {
    LOG_FILE="$1"
    FILE_LOG=true
}

# Set the log format (default: %d [%l] [%s] %m)
set_log_format() {
    LOG_FORMAT="$1"
}

# Log functions for different levels
log_debug() {
    log_message "DEBUG" $DEBUG "$1"
}

log_info() {
    log_message "INFO" $INFO "$1"
}

log_warning() {
    log_message "WARNING" $WARNING "$1"
}

log_error() {
    log_message "ERROR" $ERROR "$1"
}

log_critical() {
    log_message "CRITICAL" $CRITICAL "$1"
}

# Example of usage
# If sourced in another script, this part will not execute
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_logger -L INFO -l "app.log" -v
    log_info "This is an info message"
    log_debug "This is a debug message"
    log_warning "This is a warning message"
    log_error "This is an error message"
    log_critical "This is a critical message"
fi
