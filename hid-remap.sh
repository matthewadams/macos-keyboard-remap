#!/usr/bin/env bash

usage() {
cat <<EOF
  usage:
  $0 -p productId remappings

  options:
  -p,--product-id: productId The keyboard product id (from Menu Bar\\⌥\SystemInformation...\Hardware)

  remappings: one or more colon-separated source/destination HID keyboard/keypad ID pairs; if restoring mapping, you may omit the colon & second ID

  Example: swap left-gui to left-option & right-gui to right-option
    $0 -p 0x0817 E2:E3 E3:E2 E6:E7 E7:E6

  Example: restore mapping above
    $0 -p 0x0817 E2 E3 E6 E7
EOF
}

if echo "$@" | grep -q help; then
  usage
  exit 0
fi

shift
HIDUTIL_PRODUCT_ID=$1
if [ -z "$HIDUTIL_PRODUCT_ID" ]; then
  usage
  exit 1
fi
shift

if [ -z "$@" ]; then # no mappings
  exit 0
fi

sep=
mappings='{"UserKeyMapping":['
for mapping in $@; do
  sd=(${mapping//:/ })
  src=${sd[0]}
  dst=${sd[1]}
  if [ -z "$src" ]; then
    usage
    exit 2
  fi
  if [ -z "$dst" ]; then
    dst=$src
  fi
  src="$(echo -n $src | tr '[:lower:]' '[:upper:]')"
  dst="$(echo -n $dst | tr '[:lower:]' '[:upper:]')"
  
  mappings="$mappings$sep{\"HIDKeyboardModifierMappingSrc\":0x7000000$src,\"HIDKeyboardModifierMappingDst\":0x7000000$dst}"

  if [ -z "$sep" ]; then
    sep=,
  fi
done
mappings="$mappings]}"

hidutil property --matching "{\"ProductID\":$HIDUTIL_PRODUCT_ID}" --set "$mappings"
