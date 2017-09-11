#!/usr/bin/env bash

set +e

source "bin/log.sh"

function ensure_valid_core_sim_service {
	for try in {1..4}; do
    info "Attempting to load CoreSimulator service: $try of 4 tries"
		xcrun simctl help &>/dev/null
    if [ $? -eq 0 ]; then
      info "Valid CoreSimulator service is loaded!"
      break
    else
      sleep 1.0
    fi
	done
}
