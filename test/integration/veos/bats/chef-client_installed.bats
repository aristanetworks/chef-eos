#!/usr/bin/env bats

@test "chef-client binary is found in PATH" {
  run which chef-client
  [ "$status" -eq 0 ]
}
