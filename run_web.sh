#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
flutter pub get
dart run tool/hotel_proxy.dart &
staygo_gateway_pid=$!
trap 'kill "$staygo_gateway_pid" 2>/dev/null || true' EXIT
flutter run -d chrome --web-port=7359 --dart-define=STAYGO_API_URL=http://127.0.0.1:8765/api
