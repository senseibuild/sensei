require 'docile'
require 'sensei/ruleset'
require 'sensei/compiler'

module Sensei
  class PackageHelper
    def self.get_outputs(args)
      outputs = Array.new

      args = [ args ] unless args.is_a? Array
      args.each do |output|
        if output.is_a? CompilerConfiguration then
          outputs.concat get_outputs(output.builders)
        elsif output.is_a? CompilerBuilder then
          outputs.concat get_outputs(output.get_outputs)
        elsif output.is_a? Array then
          outputs.concat get_outputs(output)
        else
          output = [ output ] unless output.is_a? Array
          outputs.concat output if output.is_a? Array
        end
      end

      outputs
    end
  end

  class PackageWriter
    def initialize(package, file)
      @package = package
      @file = file
    end

    def build(output, input, rule, configuration)
      input = [ input ] unless input.is_a? Array
      input = input.map { |f| f.to_build.to_s }
      @file << "build #{output.to_build}: #{rule} #{input.join(' ')}\n"
      configuration.write_ninja @file, rule, '  ' if !!configuration
    end
  end

  class Package
    include RulesetCapable

    attr_reader :name, :root_path

    def initialize(name, root_path)
      @name = name
      @root_path = root_path
      @root_path = Pathname.new root_path if root_path.is_a? String
      @configs = Hash.new
      @outputs = Array.new
    end

    def glob(*args)
      files = Array.new

      args.each do |pattern|
        Pathname.glob(@root_path + pattern) do |f|
          files << CompilerFile.new(self, :package, f.relative_path_from(@root_path))
        end
      end

      files
    end

    def find_compiler(name)
      cmp = nil
      mod = Sensei.application.current_module

      while mod != nil && cmp == nil do
        cmp = mod.compilers[name]
        mod = mod.parent
      end

      cmp
    end

    def compiler(name, *args, &block)
      begin
        cmp = find_compiler name
        config = cmp.create_config self, *args, &block
        @configs[name] = config
        config
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end

    def build(files, cmp, *args, &block)
      begin
        files = PackageHelper.get_outputs files

        builder = cmp.compiler.create_builder self, *args, &block
        builder.add_files *files
        cmp.add_builder builder
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end

    def outputs(*args)
      begin
        @outputs.concat PackageHelper.get_outputs(args)
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
    end

    def write_ninja(file)
      writer = PackageWriter.new self, file

      @configs.each do |k, config|
        config.write_ninja file, k
        file << "\n"

        config.builders.each do |builder|
          builder.write_ninja writer, k
          file << "\n"
        end if !!config.builders
      end

      if @outputs.length > 0 then
        outputs = @outputs.map { |o| o.to_build.to_s }.join(' ')
        file << "build package_#{@name}: phony #{outputs}\n"
      end
    end
  end
end
