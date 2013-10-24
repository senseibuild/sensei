require 'sensei/compiler'

module Sensei
  module Compilers
    class CCompilerConfiguration < CompilerConfiguration
      def flags(*args)
        add_config :flags, args.join(' ')
      end

      def includes(*args)
        flags args.map! { |i| "-I#{i}" }
      end

      def defines(args)
        args.each do |k, v|
          f = "-D#{k}"
          f += "=#{v}" if !!v
          flags f
        end
      end

      def using(*packages)
        includes packages.includes if !!packages.includes
        defines packages.defines if !!packages.defines
      end
    end

    class CCompilerBuilder < CompilerBuilder
      def get_output_name(name)
        name.change_extension(".o").change_type(:packagebuild)
      end
    end

    class CCompiler < Compiler
      def initialize(name, *args, &block)
        super *args, &block
        @name = name
        @description = "CC $in"
      end

      def write_ninja(writer, name)
        writer.var :command, "#{@name} -MMD -MT $out -MF $out.d $#{name}_flags -c $in -o $out"
        writer.var :description, @description
      end

      def create_config(package, *args, &block)
        CCompilerConfiguration.new package, self, *args, &block
      end

      def create_builder(package, *args, &block)
        CCompilerBuilder.new package, create_config(package, *args, &block)
      end
    end
  end
end
