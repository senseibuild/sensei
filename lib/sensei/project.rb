require 'docile'
require 'ostruct'
require 'sensei/configurable'
require 'sensei/rule'
require 'sensei/file'
require 'sensei/utils'

module Sensei
  class Project
    include Configurable
    attr_reader :name, :parent, :path

    def initialize(parent, name)
      @name = name
      @parent = parent
      @path = parent.path
      @builds = Array.new
    end

    def find_packages(*args)
      args.map do |pkg|
        Sensei.driver.package_manager.get pkg
      end
    end

    def glob(*args)
      files = Array.new

      args.each do |pattern|
        Pathname.glob(@path + pattern) do |f|
          files << SenseiFile.new(self, :project, f.relative_path_from(@parent.path))
        end
      end

      files
    end

    def mglob(dirs, *args)
      dirs.map do |dir|
        files.concat glob(*args.map { |f| File.join(dir, f) })
      end.flatten
    end

    def file(file, type = :project)
      SenseiFile.new(self, type, file)
    end

    def files(*files)
      files.map do |f|
        file f, :project
      end
    end

    def files2(type, *files)
      files.map do |f|
        file f, type
      end
    end

    def full(file)
      SenseiFile.new(nil, :full, file)
    end

    def build(rulename, input, *args, &block)
      begin
        rule = @parent._find_rule rulename
        config = rule.create_config *args, &block
        builder = rule.create_builder rulename, config, SenseiUtils.get_outputs(input)
        @builds << builder
        builder
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end

    def register_package(args)
      args = OpenStruct.new args if args.is_a? Hash
      Sensei.driver.package_manager.register @name, args
    end

    def _write_ninja(w)
      @builds.each do |v|
        v.write_ninja w
      end
    end
  end
end
