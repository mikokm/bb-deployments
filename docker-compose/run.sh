#!/usr/bin/env bash
set -eu

# ----------- CONFIG -----------
worker_fuse="worker-fuse-ubuntu22-04"
worker_hardlinking="worker-hardlinking-ubuntu22-04"
fuse_dir_to_unmount="volumes/${worker_fuse}/build"
sudo -v

# ----------- PARAMETER HANDLING -----------
if [ $# -eq 0 ] || [ "$1" = "help" ]; then
    echo "Usage: $0 [fuse|hardlinking|both] [docker-compose-args...]"
    exit 1
fi

WORKER_TYPE="$1"
shift # Remove the worker type parameter

USE_FUSE=0
USE_HARDLINKING=0

case "$WORKER_TYPE" in
    fuse)
        USE_FUSE=1
        ;;
    hardlinking)
        USE_HARDLINKING=1
        ;;
    both)
        USE_FUSE=1
        USE_HARDLINKING=1
        ;;
    *)
        echo "Unknown worker type: $WORKER_TYPE"
        echo "Usage: $0 [fuse|hardlinking|both] [docker-compose-args...]"
        exit 1
        ;;
esac

# ----------- FUNCTIONS -----------

setup () {
    local -
    set -x

    docker compose --profile fuse --profile hardlinking down --remove-orphans

    if [ "$USE_FUSE" = "1" ]; then
        { sudo fusermount -u "$fuse_dir_to_unmount" && sleep 1; } || true
    fi

    sudo rm -rf volumes/bb "volumes/${worker_fuse}" "volumes/${worker_hardlinking}"

    mkdir -p volumes

    # Always create both sets of directories for compatibility with docker compose volumes
    mkdir -m 0777 "volumes/${worker_fuse}" "volumes/${worker_fuse}"/{build,cas,cas/persistent_state}
    mkdir -m 0777 "volumes/${worker_hardlinking}" "volumes/${worker_hardlinking}"/{build,cas,cas/persistent_state}
    mkdir -m 0700 "volumes/${worker_fuse}/cache" "volumes/${worker_hardlinking}/cache"
    mkdir -p volumes/storage-{ac,cas}-{0,1}/persistent_state
    chmod 0700 volumes/storage-{ac,cas}-{0,1}/{,persistent_state}
}

cleanup() {
    EXIT_STATUS=$?
    local -
    set -x

    if [ "$USE_FUSE" = "1" ]; then
        sudo fusermount -u "$fuse_dir_to_unmount" || true
    fi
    exit "$EXIT_STATUS"
}

# Only register automatic unmount if FUSE is enabled
if [ "$USE_FUSE" = "1" ] && [ $# -eq 0 ]; then
    echo "Registering automatic unmount for $fuse_dir_to_unmount"
    trap cleanup EXIT
elif [ "$USE_FUSE" = "1" ]; then
    echo "When finished, manually unmount $fuse_dir_to_unmount"
fi

setup

# Compose profiles
PROFILE_ARGS=()
if [ "$USE_FUSE" = "1" ] && [ "$USE_HARDLINKING" = "1" ]; then
    PROFILE_ARGS=(--profile fuse --profile hardlinking)
elif [ "$USE_FUSE" = "1" ]; then
    PROFILE_ARGS=(--profile fuse)
elif [ "$USE_HARDLINKING" = "1" ]; then
    PROFILE_ARGS=(--profile hardlinking)
fi

docker compose "${PROFILE_ARGS[@]}" up "$@"

