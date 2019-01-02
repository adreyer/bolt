require 'bolt_spec/run'
require 'bolt/config'
require 'bolt/boltdir'
require 'bolt/inventory'

class Bolt::DSL < BoltSpec::Run::BoltRunner

  def self.run(**options, &block)
    dsl = new(options)
    # This just allows us to play with syntax.
    dsl.instance_eval(&block)
  end

  attr_reader :inventory

  def initialize(inventory: nil, config: {}, boltdir: nil)
    @boltdir = boltdir ? Bolt::Boltdir.new(boltdir) : Bolt::Boltdir.find_boltdir(Dir.pwd)
    @config = Bolt::Config.from_boltdir(@boltdir, config)
    @inventory = inventory ? Bolt::Inventory.new(inventory) : Bolt::Inventory.from_config(@config)

    #setup analytics
    super(@config, @inventory)
  end
end
