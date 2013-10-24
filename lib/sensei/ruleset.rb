require 'docile'

module Sensei
  module RulesetCapable
    def import(*args)
      args.each do |ruleset|
        Docile.dsl_eval(self, &ruleset.rules)
      end
    end
  end

  class Ruleset
    include RulesetCapable
    attr_reader :rules

    def initialize(&rules)
      @rules = rules
    end
  end
end
