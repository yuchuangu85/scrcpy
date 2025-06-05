#!/usr/bin/env bash
set -ex
DEPS_DIR=$(dirname ${BASH_SOURCE[0]})
cd "$DEPS_DIR"
. common
process_args "$@"

VERSION=2.32.2
FILENAME=SDL-$VERSION.tar.gz
PROJECT_DIR=SDL-release-$VERSION
SHA256SUM=f2c7297ae7b3d3910a8b131e1e2a558fdd6d1a4443d5e345374d45cadfcb05a4

cd "$SOURCES_DIR"

if [[ -d "$PROJECT_DIR" ]]
then
    echo "$PWD/$PROJECT_DIR" found
else
    get_file "https://github.com/libsdl-org/SDL/archive/refs/tags/release-$VERSION.tar.gz" "$FILENAME" "$SHA256SUM"
    tar xf "$FILENAME"  # First level directory is "$PROJECT_DIR"
    patch -d "$PROJECT_DIR" -p1 < "$PATCHES_DIR"/SDL-pipewire-Ensure-that-the-correct-struct-is-used-for-.patch
fi

mkdir -p "$BUILD_DIR/$PROJECT_DIR"
cd "$BUILD_DIR/$PROJECT_DIR"

export CFLAGS='-O2'
export CXXFLAGS="$CFLAGS"

if [[ -d "$DIRNAME" ]]
then
    echo "'$PWD/$HDIRNAME' already exists, not reconfigured"
    cd "$DIRNAME"
else
    mkdir "$DIRNAME"
    cd "$DIRNAME"

    conf=(
        --prefix="$INSTALL_DIR/$DIRNAME"
    )

    if [[ "$HOST" == linux ]]
    then
        conf+=(
            --enable-video-wayland
            --enable-video-x11
        )
    fi

    if [[ "$LINK_TYPE" == static ]]
    then
        conf+=(
            --enable-static
            --disable-shared
        )
    else
        conf+=(
            --disable-static
            --enable-shared
        )
    fi

    if [[ "$BUILD_TYPE" == cross ]]
    then
        conf+=(
            --host="$HOST_TRIPLET"
        )
    fi

    "$SOURCES_DIR/$PROJECT_DIR"/configure "${conf[@]}"
fi

make -j
# There is no "make install-strip"
make install
# Strip manually
if [[ "$LINK_TYPE" == shared && "$HOST" == win* ]]
then
    ${HOST_TRIPLET}-strip "$INSTALL_DIR/$DIRNAME/bin/SDL2.dll"
fi
