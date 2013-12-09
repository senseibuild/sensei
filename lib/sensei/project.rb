require 'docile'
require 'sensei/configurable'
require 'sensei/rule'
require 'sensei/file'

module Sensei
  class ProjectHelper
    def self.get_outputs(args)
      outputs = Array.new

      args = [ args ] unless args.is_a? Array
      args.each do |output|
        if output.respond_to? :get_output then
          outputs.concat get_outputs(output.get_output)
        elsif output.is_a? Array then
          outputs.concat get_outputs(output)
        else
          outputs << output
        end
      end

      outputs
    end
  end

  class Project
    include Configurable
    attr_reader :name, :parent, :path

    def initialize(parent, name)
      @name = name
      @parent = parent
      @path = parent.path
      @builds = Array.new
    end

    def glob(*args)
      files = Array.new

      args.each do |pattern|
        Pathname.glob(@parent.path + pattern) do |f|
          files << SenseiFile.new(self, :project, f.relative_path_from(@parent.path))
        end
      end

      files
    end

    def file(file, type = :project)
      SenseiFile.new(self, type, file)
    end

    def files(*files)
      f = Array.new

      files.each do |fname|
        f << file(fname, :project)
      end

      f
    end

    def files2(type, *files)
      f = Array.new

      files.each do |fname|
        f << file(fname, type)
      end

      f
    end

    def full(file)
      SenseiFile.new(nil, :full, file)
    end

    def build(rulename, input, *args, &block)
      begin
        rule = @parent._find_rule rulename
        config = rule.create_config *args, &block
        builder = rule.create_builder(rulename, config, ProjectHelper.get_outputs(input))
        @builds << builder
        builder
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end

    def _write_ninja(w)
      @builds.each do |v|
        v.write_ninja w
      end
    end
  end
end
