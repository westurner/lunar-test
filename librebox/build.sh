#!/usr/bin/env bash
set -e

__THIS=$0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMAKE_GENERATOR="Ninja"
CMAKE_BUILD_TYPE="Release"
CMAKE_TOOLSET=""
ARCH="x64"


# Allow conda-forge environment overrides
PROJECT_ROOT="${PROJECT_ROOT:-$SCRIPT_DIR}"
BUILD_DIR="${BUILD_DIR:-${BUILD_PREFIX:-$PROJECT_ROOT/build}}"
DIST_DIR="${DIST_DIR:-${PREFIX:-$PROJECT_ROOT/dist}}"
CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-${PREFIX:-$PROJECT_ROOT/third_party/vendor}}"



# Git clone URLs and refs for dependencies
LUAU_GIT_URL=${LUAU_GIT_URL:-https://github.com/luau-lang/luau.git}
LUAU_GIT_REF=${LUAU_GIT_REF:-}
RAYLIB_GIT_URL=${RAYLIB_GIT_URL:-https://github.com/raysan5/raylib.git}
RAYLIB_GIT_REF=${RAYLIB_GIT_REF:-}

# Allow overwrite of vendored libs
ALLOW_OVERWRITE_VENDORED_LIBS=${ALLOW_OVERWRITE_VENDORED_LIBS:-0}

LUAU_SOURCE_DIR="$PROJECT_ROOT/luau"
LUAU_BUILD_DIR="$LUAU_SOURCE_DIR/build"
VENDOR_DIR="$PROJECT_ROOT/third_party/vendor"


# Clone a git repo, moving existing dir aside if ALLOW_OVERWRITE_VENDORED_LIBS is set
function git_clone_with_backup() {
    local repo_url="$1"
    local repo_ref="$2"
    local target_dir="$3"
    local name="$4"
    if [ "$ALLOW_OVERWRITE_VENDORED_LIBS" != "0" ] && [ -d "$target_dir" ]; then
        local ts=$(date +%Y%m%d-%H%M%S)
        mv "$target_dir" "${target_dir}.bak.$ts"
        echo "Moved existing $name to ${target_dir}.bak.$ts"
    fi
    if [ ! -d "$target_dir" ]; then
        echo "Cloning $name..."
        if [ -n "$repo_ref" ]; then
            git clone --depth 1 --branch "$repo_ref" "$repo_url" "$target_dir"
        else
            git clone --depth 1 "$repo_url" "$target_dir"
        fi
    fi
}

function build_dependencies() {
    echo "=========================================================="
    echo "          BUILDING THIRD-PARTY DEPENDENCIES"
    echo "=========================================================="

    echo

    echo "[1/4] Configuring Luau..."
    echo "     Source: $LUAU_SOURCE_DIR"
    echo "     Build:  $LUAU_BUILD_DIR"
    echo "     Install Destination: $VENDOR_DIR/luau"

    git_clone_with_backup "$LUAU_GIT_URL" "$LUAU_GIT_REF" "$LUAU_SOURCE_DIR" "Luau"

    mkdir -p "$LUAU_BUILD_DIR"
    pushd "$LUAU_BUILD_DIR"

    cmake "$LUAU_SOURCE_DIR" -G "$CMAKE_GENERATOR" -DCMAKE_INSTALL_PREFIX="$VENDOR_DIR/luau"
    echo
    echo "[2/4] Building Luau ($CMAKE_BUILD_TYPE)..."
    cmake --build . --config "$CMAKE_BUILD_TYPE"
    echo
    echo "[3/4] Installing Luau to vendor directory..."
    cmake --install . --config "$CMAKE_BUILD_TYPE"

    popd

    # Raylib setup
    RAYLIB_SRC_DIR="$VENDOR_DIR/raylib-src"
    RAYLIB_BUILD_DIR="$VENDOR_DIR/raylib-build"
    RAYLIB_INSTALL_DIR="$VENDOR_DIR/raylib"
    git_clone_with_backup "$RAYLIB_GIT_URL" "$RAYLIB_GIT_REF" "$RAYLIB_SRC_DIR" "raylib"
    echo "[4/4] Building and installing raylib..."
    mkdir -p "$RAYLIB_BUILD_DIR"
    pushd "$RAYLIB_BUILD_DIR"
    cmake "$RAYLIB_SRC_DIR" -G "$CMAKE_GENERATOR" -DCMAKE_INSTALL_PREFIX="$RAYLIB_INSTALL_DIR" -DBUILD_EXAMPLES=OFF -DBUILD_GAMES=OFF
    cmake --build . --config "$CMAKE_BUILD_TYPE"
    cmake --install . --config "$CMAKE_BUILD_TYPE"
    popd

    echo
    echo "=========================================================="
    echo "         DEPENDENCIES BUILT AND INSTALLED!"
    echo "         You can now run build.sh engine"
    echo "=========================================================="
}

function build_engine() {
    NO_CLEAN=0
    # Optionally override paths via positional args: engine [BUILD_DIR] [DIST_DIR] [CMAKE_PREFIX_PATH]
    local _build_dir="$BUILD_DIR"
    local _dist_dir="$DIST_DIR"
    local _cmake_prefix_path="$CMAKE_PREFIX_PATH"
    # local idx=0
    for arg in "$@"; do
        case "$arg" in
            --no-clean)
                NO_CLEAN=1
                ;;
            *)
                # case $idx in
                #     0) _build_dir="$arg" ;;
                #     1) _dist_dir="$arg" ;;
                #     2) _cmake_prefix_path="$arg" ;;
                # esac
                # idx=$((idx+1))
                echo "ERROR: Unsupported argument: '$1'. Try setting BUILD_DIR, DIST_DIR, or CMAKE_PREFIX_PATH."
                ;;
        esac
    done

    echo "=========================================================="
    echo "                BUILDING LIBREBOX ENGINE"
    echo "=========================================================="

    echo
    if [[ "$NO_CLEAN" -eq 0 ]]; then
        echo "[1/4] Cleaning build directory only..."
        rm -rf "$_build_dir"
    else
        echo "[1/4] Skipping clean (because -no-clean was specified)"
    fi

    echo
    echo "[2/4] Configuring lunarengine..."
    echo "     Build Dir: $_build_dir"
    mkdir -p "$_build_dir"
    pushd "$_build_dir"

    cmake "$PROJECT_ROOT" -G "$CMAKE_GENERATOR" -DCMAKE_PREFIX_PATH="$_cmake_prefix_path"
    echo
    echo "[3/4] Building lunarengine ($CMAKE_BUILD_TYPE)..."
    cmake --build . --config "$CMAKE_BUILD_TYPE"
    echo
    echo "[4/4] Installing to 'dist'..."
    cmake --install . --prefix "$_dist_dir" --config "$CMAKE_BUILD_TYPE"

    popd
    echo
    echo "=========================================================="
    echo "                BUILD SUCCESSFUL"
    echo "=========================================================="
}


print_usage() {
    echo "Usage: $0 [dependencies|engine] [options]"
    exit 1
}
function main() {
    if [[ $# -eq 0 ]]; then
        # print_usage
        set -- "all"
    fi

    for arg in "$@"; do
        case "$arg" in
            -h|--help|help)
                print_usage
                return 0
                ;;
        esac
    done

    for arg in "$@"; do
        case "$arg" in
            dependencies)
                build_dependencies
                ;;
            engine)
                shift
                build_engine "$@"
                break
                ;;
            all)
                build_dependencies
                shift
                build_engine "$@"
                break
                ;;
            *)
                echo "ERROR: Unrecognized arg: $1 ($@)" >&2
                return 2
                ;;
        esac
    done
}

main "$@"