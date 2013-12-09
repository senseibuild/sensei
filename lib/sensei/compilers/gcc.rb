require 'sensei/rule'

module Sensei
  module Compilers
    class CCompilerConfiguration < NinjaConfiguration
      attr_reader :packages

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

      def using(*args)
        @packages.concat args
      end

      def _resolve_packages
        @packages.each do |pkg|
          pkg = pkg.resolve if pkg.respond_to? :resolve

          _package_include pkg, :includes
          _package_include pkg, :defines
        end
      end

      def _package_include(package, method)
        send method, package.send(method) if package.respond_to? method
      end
    end

    class CCompilerBuilder < RuleBuilder
      def initialize(rule, config, input)
        input = [input] if not input.is_a? Array
        super rule, config, input
      end

      def get_output_name(input)
        input.convert('.o', :projectbuild)
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

    class CLinkerConfiguration < NinjaConfiguration
      attr_reader :packages, :input, :platform, :_output

      def initialize(*args, &block)
        @packages = Array.new
        @input = Array.new
        super *args, &block
      end

      def flags(*args)
        _append_config :flags, args.flatten.join(' ') + ' '
      end

      def libdir(*args)
        flags *args.flatten.map! { |i| "-L#{i.to_build}" }
      end

      def library(*args)
        flags *args.flatten.map! { |i| "-l#{i}" }
      end

      def libinput(*args)
        @input.concat args.flatten
      end

      def script(path)
        flags "-T", path.to_build.to_s
      end

      def output(output)
        @_output = output
      end

      def _resolve_packages
        @packages.each do |pkg|
          pkg = pkg.resolve if pkg.respond_to? :resolve

          _package_include pkg, :libdir
          _package_include pkg, :library
          _package_include pkg, :libinput
        end
      end

      def _package_include(package, method)
        send method, package.send(method) if package.respond_to? method
      end
    end

    class CLinkerBuilder < RuleBuilder
      def initialize(rule, config, input)
        input = [input] if not input.is_a? Array
        super rule, config, input
      end

      def get_output_name(input)
        input.convert('.o', :packagebuild)
      end

      def get_output
        @config._output
      end

      def write_ninja(w)
        @config._resolve_packages
        write_build w, @rule, get_output, @input + @config.input, @config
      end
    end

    class CLinker < Rule
      def initialize(path)
        super() do
          description "LINK $out"
          command "#{path} -o $out $flags $in"
        end
      end

      def create_config(*args, &block)
        CLinkerConfiguration.new *args, &block
      end

      def create_builder(rule, config, input)
        CLinkerBuilder.new rule, config, input
      end
    end
  end
end
