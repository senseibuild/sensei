require 'docile'

module Sensei
  module Configurable
    def import(*args)
      args.each do |config|
        next if not config
        import *config.parents if config.parents
        Docile.dsl_eval self, &config.rules if config.rules
      end
    end
  end

  class Configuration
    attr_reader :parents, :rules

    def initialize(*parents, &rules)
      @parents = parents
      @rules = rules
    end
  end
end
