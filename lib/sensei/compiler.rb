require 'docile'
require 'sensei/ruleset'

module Sensei
  class CompilerFile
    attr_reader :package, :type, :path

    def initialize(package, type, path)
      @package = package
      @type = type
      @path = path
      @path = Pathname.new @path if @path.is_a? String
    end

    def to_build
      if @type == :build or @type == :full then
        path = @path
      elsif @type == :root then
        path = Sensei.relative_path_from_build @path
      elsif @type == :package then
        path = Sensei.relative_path_from_build @package.root_path + @path
      elsif @type == :packagebuild then
        path = Sensei.relative_path_from_build Sensei.application.options.output_directory + @package.root_path + @path
      end

      CompilerFile.new @package, :build, path
    end

    def change_extension(ext)
      CompilerFile.new @package, @type, path.sub_ext(ext)
    end

    def change_type(type)
      CompilerFile.new @package, type, @path
    end

    def to_path
      @path.to_s
    end

    def to_s
      @path.to_s
    end
  end

  class CompilerBuilder
    include RulesetCapable

    attr_reader :package, :configuration

    def initialize(package, configuration)
      @package = package
      @configuration = configuration
      @files = Array.new
    end

    def add_files(*files)
      @files.concat files
    end

    def get_output_name(name)
      name
    end

    def get_outputs
      @files.map { |f| get_output_name(f) }
    end

    def write_ninja(writer, rule)
      @files.each do |file|
        writer.build get_output_name(file), file, rule, @configuration
      end
    end
  end

  class CompilerConfiguration
    include RulesetCapable

    attr_reader :package, :compiler, :builders

    def initialize(package, compiler, *args, &block)
      @package = package
      @compiler = compiler
      @override_set = Set.new
      @config_map = Hash.new
      @config_map.default = ""

      import *args
      Docile.dsl_eval(self, &block) if !!block
    end

    def add_builder(builder)
      @builders ||= Array.new
      @builders << builder
    end

    def add_config(name, value)
      @config_map[name] += value
    end

    def override_config(name, override = true)
      if override then
        @override_map.add name
      else
        @override_set.delete name
      end
    end

    def write_ninja(file, name, level = '')
      @config_map.each do |key, value|
        file << "#{level}#{name}_#{key} = "
        file << "$#{name}_#{key} " unless @override_set.include? key
        file << "#{value}\n"
      end
    end
  end

  class Compiler
    attr_reader :configuration

    def initialize(*args, &block)
      @configuration = create_config nil, *args, &block
    end

    def write_ninja(writer)

    end

    def create_config(package, *args, &block)
      CompilerConfiguration.new package, *args, &block
    end

    def create_builder(package, *args, &block)
      CompilerBuilder.new package, create_config(package, *args, &block)
    end
  end

  class CompilerWriter
    def initialize(file, name, compiler)
      @file = file
      @name = name

      compiler.configuration.write_ninja file, name
      file << "\n"
      file << "rule #{name}\n"
      compiler.write_ninja self, name
      file << "\n"
    end

    def var(name, value = nil)
      @file << "  #{name}"
      @file << " = #{value}" if !!value
      @file << "\n"
    end
  end
end
