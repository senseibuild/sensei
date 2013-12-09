require 'docile'
require 'sensei/configurable'

module Sensei
  class NinjaConfiguration
    include Configurable

    def self.config_entry(*names)
      names.each do |name|
        name = name.to_s
        define_method name do |value|
          _set_config name, value
        end
      end
    end

    def initialize(*args, &block)
      @config = Hash.new
      import *args
      Docile.dsl_eval self, &block if block
    end

    def _set_config(name, value)
      @config[name] = value
    end

    def _append_config(name, value)
      @config[name] ||= ''
      @config[name] += value
    end

    def _write_ninja(w, level = '')
      @config.each do |k, v|
        if v then
          w << "#{level}#{k} = #{v}\n"
        else
          w << "#{level}#{k}\n"
        end
      end
    end
  end

  class RuleConfiguration < NinjaConfiguration
    config_entry :command
    config_entry :description
    config_entry :deps, :depfile
    config_entry :restat
    config_entry :rspfile, :rspfile_content
  end

  class RuleBuilder
    attr_reader :rule, :config, :input

    def initialize(rule, config, input)
      @rule = rule
      @config = config
      @input = input
    end

    def write_ninja(w)
      write_build w, @rule, get_output, @input, @config
    end

    def write_build(w, rule, output, input = nil, config = nil, deps = nil, orderDeps = nil)
      output = [output] if not output.is_a? Array
      input = [input] if input and not input.is_a? Array
      deps = [deps] if deps and not deps.is_a? Array
      orderDeps = [orderDeps] if orderDeps and not orderDeps.is_a? Array

      if output then
        output.map! do |i|
          i.to_build
        end
      end

      if input then
        input.map! do |i|
          i.to_build
        end
      end

      if deps then
        deps.map! do |i|
          i.to_build
        end
      end

      if orderDeps then
        orderDeps.map! do |i|
          i.to_build
        end
      end

      output.each do |o|
        o.mkbasepath
      end

      w << "build #{output.join(' ')}: #{rule}"
      w << " #{input.join(' ')}" if input
      w << " | #{deps.join(' ')}" if deps
      w << " || #{orderDeps.join(' ')}" if orderDeps
      w << "\n"
      config._write_ninja w, '  '
    end
  end

  class Rule
    def initialize(*args, &block)
      @config = RuleConfiguration.new *args, &block
    end

    def create_config(*args, &block)

    end

    def create_builder(rule, config, input)

    end

    def write_ninja(name, w)
      w << "rule #{name}\n"
      @config._write_ninja w, '  '
    end
  end
end
