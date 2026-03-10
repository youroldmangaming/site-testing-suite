#!/usr/bin/env bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[done]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*"; exit 1; }

NO_CACHE=false
[ "$1" = "-n" ] || [ "$1" = "--no-cache" ] && NO_CACHE=true

[ -f "Dockerfile" ]         || error "Dockerfile not found. Run from the project root."
[ -f "docker-compose.yml" ] || error "docker-compose.yml not found."
docker info > /dev/null 2>&1 || error "Docker is not running."

info "Building image: auto-test"
BUILD_ARGS="--tag auto-test ."
$NO_CACHE && BUILD_ARGS="--no-cache $BUILD_ARGS"
docker build $BUILD_ARGS

success "Image built. Run ./run-tests.sh to execute the tests."
