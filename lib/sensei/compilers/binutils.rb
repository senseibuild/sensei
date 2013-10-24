require 'sensei/compiler'

module Sensei
  module Compilers
    class LibraryCompilerConfiguration < CompilerConfiguration
      def output(path)
        @output = path
      end

      def get_output
        @output
      end
    end

    class LibraryCompilerBuilder < CompilerBuilder
      def get_outputs
        [ get_output_name(configuration.get_output) ]
      end

      def get_output_name(name)
        name.change_extension ".a"
      end

      def write_ninja(writer, rule)
        writer.build get_output_name(configuration.get_output), @files, rule, @configuration
      end
    end

    class LibraryCompiler < Compiler
      def initialize(name, *args, &block)
        super *args, &block
        @name = name
        @description = "AR $out"
      end

      def write_ninja(writer, name)
        writer.var :command, "#{@name} rvs $out $in"
        writer.var :description, @description
      end

      def create_config(package, *args, &block)
        LibraryCompilerConfiguration.new package, self, *args, &block
      end

      def create_builder(package, *args, &block)
        LibraryCompilerBuilder.new package, create_config(package, *args, &block)
      end
    end

    class LinkerCompilerConfiguration < CompilerConfiguration
      def initialize(package, compiler, *args, &block)
        @output = CompilerFile.new package, :packagebuild, package.name if !!package
        super package, compiler, *args, &block
      end

      def output(path, type = :packagebuild)
        @output = CompilerFile.new @package, type, path
      end

      def get_output
        @output
      end

      def shared
        @shared = true
        flags '-shared'
      end

      def is_shared
        @shared || false
      end

      def flags(*args)
        add_config :flags, args.join(' ')
      end

      def library(*args)
        flags args.map! { |i| "-l#{i}" }
      end

      def using(*packages)
        library packages.libraries if !!packages.libraries
      end
    end

    class LinkerCompilerBuilder < CompilerBuilder
      def get_library_name
        configuration.get_output.change_extension('.so') if !Sensei.is_windows
        configuration.get_output.change_extension('.dll') if Sensei.is_windows
      end

      def get_outputs
        outs = Array.new

        if configuration.is_shared then
          outs << get_library_name
          outs << get_library_name.change_extension('.a') if Sensei.is_windows
        else
          outs << configuration.get_output
        end

        outs
      end

      def write_ninja(writer, rule)
        writer.build get_library_name, @files, rule, @configuration

        if Sensei.is_windows then
          writer.build get_library_name.change_extension('.a'), get_library_name, 'phony', nil
        end
      end
    end

    class LinkerCompiler < Compiler
      def initialize(name, *args, &block)
        super *args, &block
        @name = name
        @description = "LINK $out"
      end

      def write_ninja(writer, name)
        writer.var :command, "#{@name} $#{name}_flags -o $out $in"
        writer.var :description, @description
      end

      def create_config(package, *args, &block)
        LinkerCompilerConfiguration.new package, self, *args, &block
      end

      def create_builder(package, *args, &block)
        LinkerCompilerBuilder.new package, create_config(package, *args, &block)
      end
    end
  end
end
