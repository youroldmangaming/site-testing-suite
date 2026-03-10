#!/usr/bin/env bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[done]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*"; exit 1; }

BROWSER="chrome"
SUITE="test"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--browser) BROWSER="$2"; shift 2 ;;
    -s|--suite)   SUITE="$2";   shift 2 ;;
    *) error "Unknown option: $1" ;;
  esac
done

[ -f "docker-compose.yml" ] || error "docker-compose.yml not found. Run from the project root."
docker info > /dev/null 2>&1 || error "Docker is not running."
[ "$BROWSER" = "both" ] && SUITE="test:cross-browser"

info "Browser: $BROWSER"
info "Suite:   npm run $SUITE"
echo ""

BROWSER="$BROWSER" docker compose run --rm selenium-tests npm run "$SUITE"
EXIT_CODE=$?
echo ""
[ $EXIT_CODE -eq 0 ] && success "All tests passed." || error "Tests failed (exit $EXIT_CODE)."

