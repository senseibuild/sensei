require 'sensei/rule'

module Sensei
  module Compilers
    class CCompilerConfiguration < NinjaConfiguration
      include PackageCapable

      def initialize(*args, &block)
        @packages = Array.new
        super *args, &block
      end

      def flags(*args)
        _append_config :flags, args.flatten.join(' ') + ' '
      end

      def includes(*args)
        flags *args.flatten.map! { |i| "-I#{i.to_build}" }
      end

      def defines(args)
        args.each do |k, v|
          f = "-D#{k}"
          f += "=#{v}" if !!v
          flags f
        end
      end

      def _resolve_package(pkg)
        _package_use pkg, :includes
        _package_use pkg, :defines
      end
    end

    class CCompilerBuilder < RuleBuilder
      def initialize(rule, config, input)
        input = [input] unless input.is_a? Array
        super rule, config, input
      end

      def get_output_name(input)
        input.addconvert('.o', :projectbuild)
      end

      def get_output
        out = Array.new

        @input.each do |i|
          out << get_output_name(i)
        end

        out
      end

      def write_ninja(w)
        @config._resolve_packages

        @input.each do |i|
          write_build w, @rule, get_output_name(i).to_build, i.to_build, @config
        end
      end
    end

    class CCompiler < Rule
      def initialize(path)
        super() do
          description "CC $in"
          command "#{path} -MMD -MT $out -MF $out.d -c $in -o $out $flags"
          depfile "$out.d"
          deps "gcc"
        end
      end

      def create_config(*args, &block)
        CCompilerConfiguration.new *args, &block
      end

      def create_builder(rule, config, input)
        CCompilerBuilder.new rule, config, input
      end
    end

    class CPreprocessorBuilder < CCompilerBuilder
      def get_output_name(input)
        input.addconvert('.pp', :projectbuild)
      end
    end

    class CPreprocessor < Rule
      def initialize(path)
        super() do
          description "CPP $in"
          command "#{path} -MMD -MT $out -MF $out.d -E $in -o $out $flags"
          depfile "$out.d"
          deps "gcc"
        end
      end

      def create_config(*args, &block)
        CCompilerConfiguration.new *args, &block
      end

      def create_builder(rule, config, input)
        CPreprocessorBuilder.new rule, config, input
      end
    end
  end
end
