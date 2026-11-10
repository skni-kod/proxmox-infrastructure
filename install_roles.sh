#!/bin/bash

# $1 - component name

CONFIG_FILE="components/$1/ansible/roles.yml"
DEST_DIR="components/$1/ansible/roles"
REPO_URL="https://github.com/skni-kod/ansible-roles.git"

if [ -z "$CONFIG_FILE" ] || [ -z "$DEST_DIR" ]; then
  echo "Using of: $0 <config_yaml> <dest_dir>"
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file: $CONFIG_FILE doesn't exist"
  exit 1
fi

echo "Cleaning role directory ($DEST_DIR)..."
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

echo "Downloading rules base on config file: $CONFIG_FILE..."

yq e '.roles[] | .name + " " + .version' "$CONFIG_FILE" | while read -r ROLE_NAME ROLE_VERSION; do

  if [ -z "$ROLE_NAME" ] || [ "$ROLE_NAME" == "null" ]; then
    continue
  fi

  echo "-> Installing role: $ROLE_NAME (version: $ROLE_VERSION)"

  TMP_DIR=$(mktemp -d)

  git clone --branch "$ROLE_VERSION" --depth 1 "$REPO_URL" "$TMP_DIR" -q

  if [ -d "$TMP_DIR/$ROLE_NAME" ]; then
    cp -r "$TMP_DIR/$ROLE_NAME" "$DEST_DIR/$ROLE_NAME"
    echo "   Success!"
  else
    echo "   Error: Role $ROLE_NAME doesn't exist in version $ROLE_VERSION!"
  fi

  rm -rf "$TMP_DIR"
done

echo "All roles are ready to use in $DEST_DIR!"