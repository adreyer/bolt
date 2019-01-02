#!/usr/bin/env ruby

require 'bolt/dsl'


Bolt::DSL.run do
  run_command("echo #{bar}", 'localhost')
end
