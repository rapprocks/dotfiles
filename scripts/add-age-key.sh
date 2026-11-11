#!/usr/bin/env bash
set -e

HOST_NAME=$1

if [[ -z "$HOST_NAME" ]]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

run_with_pkg() {
    local pkg="$1"
    local bin="$2"
    shift 2
    if command -v "$bin" >/dev/null 2>&1; then
        "$bin" "$@"
    elif command -v nix-shell >/dev/null 2>&1; then
        nix-shell -p "$pkg" --run "$(printf '%q ' "$bin" "$@")"
    else
        echo "Error: '$bin' is not installed and 'nix-shell' is unavailable." >&2
        exit 1
    fi
}

echo "--- Generating Age key for $HOST_NAME ---"

KEY_FILE="$HOME/.config/sops/age/keys.txt"

mkdir -p "$(dirname "$KEY_FILE")"

# Generate age key
run_with_pkg age age-keygen -o "$KEY_FILE"

# Extract public recipient key
AGE_KEY=$(
    grep "public key:" "$KEY_FILE" \
    | awk '{print $4}'
)

if [[ -z "$AGE_KEY" ]]; then
    echo "Error: Could not generate age key"
    exit 1
fi

echo "Found key: $AGE_KEY"

# Export variables so yq can see them
export HOST_NAME
export AGE_KEY

echo "--- Updating .sops.yaml ---"

run_with_pkg yq yq -i -y '.keys += ["&" + strenv(HOST_NAME) + " " + strenv(AGE_KEY)]' .sops.yaml

run_with_pkg yq yq -i '(.creation_rules[] | select(.path_regex == "secrets/secrets.yaml$") | .key_groups[0].age) += ["*'"$HOST_NAME"'"]' .sops.yaml

echo "--- Updating SOPS keys ---"

run_with_pkg sops sops updatekeys secrets/secrets.yaml -y

echo "Done! $HOST_NAME is now registered in SOPS."
