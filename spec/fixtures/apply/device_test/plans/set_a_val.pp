plan device_test::set_a_val(
  $key = 'key1',
  $val = 'val1',
  $nodes = 'localhost'
) {
  # rely on the agent already being installed
  run_plan('facts', nodes => $nodes)

  $r = apply($nodes) {
    fake_device { $key:
      content => $val
    }
  }
  return $r
}
