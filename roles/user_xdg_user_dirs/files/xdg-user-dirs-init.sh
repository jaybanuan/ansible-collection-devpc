#!/bin/bash -ue

declare -a VARIABLE_NAMES=(
    XDG_DESKTOP_DIR
    XDG_DOWNLOAD_DIR
    XDG_TEMPLATES_DIR
    XDG_PUBLICSHARE_DIR
    XDG_DOCUMENTS_DIR
    XDG_MUSIC_DIR
    XDG_PICTURES_DIR
    XDG_VIDEOS_DIR
)

get_value()
{
    eval 'echo ${'$1':-}'
}

remove_descendant_dir() {
    local BASE_DIR=$1
    local TARGET_DIR=$2

    # Check that the argument "BASE_DIR" is not empty.
    if [ -z "$BASE_DIR" ]; then
        echo "Skip removing directory. The argument BASE_DIR is empty."
        return 0
    fi

    # Check that the base directory exists.
    if [ ! -d "$BASE_DIR" ]; then
        echo "Skip removing directory. The base directory $BASE_DIR does not exist."
        return 0
    fi

    # Check that the argument "TARGET_DIR" is not empty.
    if [ -z "$TARGET_DIR" ]; then
        echo "Skip removing directory. The argument TARGET_DIR is empty."
        return 0
    fi

    # Check that the target directory exists.
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Skip removing directory. The target directory "$TARGET_DIR" does not exist."
        return 0
    fi

    # Check that the target dir is descendant from base dir.
    RELATIVE_PATH=`realpath "--relative-to=$BASE_DIR" "$TARGET_DIR"`
    if [ "$RELATIVE_PATH" == "." ] || [ "$RELATIVE_PATH" == ".." ] || [ "${RELATIVE_PATH:0:3}" == "../" ]; then
        echo "The target directory $TARGET_DIR is not descendant from the base directory $BASE_DIR ."
        return 0
    fi

    # Delete the target dir.
    echo "Remove the target directory $TARGET_DIR ."
    rmdir --ignore-fail-on-non-empty "$TARGET_DIR"
}

# "C", "ja_JP.UTF-8", ...
TARGET_LANG=${1:-C}

# Get home dir and check that tilde expansion (~/) equals to env "HOME"
HOME_DIR=$(cd ~/; pwd)
if [ "$HOME_DIR" != "$HOME" ]; then
    echo "Env HOME is incorrect. ~/ == $HOME_DIR  HOME == $HOME"
    exit 1
fi

# Read user directory variables
if [ -f "$HOME_DIR/.config/user-dirs.dirs" ]; then
    source "$HOME_DIR/.config/user-dirs.dirs"
fi

# Remove current user directories
for VARIABLE_NAME in ${VARIABLE_NAMES[@]}; do
    USER_DIR=`get_value "$VARIABLE_NAME"`
    remove_descendant_dir "$HOME_DIR" "$USER_DIR"
done

# Remove current "user-dirs.dirs" .
if [ -f "$HOME_DIR/.config/user-dirs.dirs" ]; then
    rm "$HOME_DIR/.config/user-dirs.dirs"
fi

# re-initialize user directories with target LANG
LANG=$TARGET_LANG xdg-user-dirs-update --force

# "Don't ask me again"
rm "$HOME_DIR/.config/user-dirs.locale"
