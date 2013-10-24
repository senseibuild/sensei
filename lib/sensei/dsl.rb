require 'docile'
require 'sensei/ruleset'
require 'sensei/compiler'
require 'sensei/package'

module Sensei
  module DSL
    class << self
      include DSL

      def start
        import '.'
      end
    end

    def package(name, &block)
      Sensei.application.define_package Docile.dsl_eval(Package.new(name, Sensei.application.current_module.path), &block)
    end

    def compiler(compilersList)
      compilersList.each do |k, v|
        Sensei.application.define_compiler k, v
      end
    end

    def find_package(name, *args)

    end

    def import(path)
      mod = Sensei.application.enter_module path
      path = File.expand_path(File.join(mod.path, "Katafile.rb"))

      eval File.read(path), nil, path
      Sensei.application.exit_module
    end
  end
end
