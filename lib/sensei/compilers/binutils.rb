require 'sensei/rule'

module Sensei
  module Compilers
    class CLinkerConfiguration < NinjaConfiguration
      include PackageCapable
      attr_reader :input, :platform, :_output

      def initialize(*args, &block)
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

      def script(args)
        begin
          a = SenseiUtils.get_output(args)
          puts a
        flags "-T", SenseiUtils.get_output(args).to_build
      rescue => e
        puts e.inspect
        puts e.backtrace
      end
      end

      def output(output)
        @_output = output
      end

      def _resolve_package(pkg)
        _package_use pkg, :libdir
        _package_use pkg, :library
        _package_use pkg, :libinput, RuleHelpers::get_output
        _package_use pkg, :script, RuleHelpers::get_output
      end
    end

    class CLinkerBuilder < RuleBuilder
      def initialize(rule, config, input)
        input = [input] unless input.is_a? Array
        super rule, config, input
      end

      def get_output
        @config._output
      end

      def write_ninja(w)
        @config._resolve_packages
        write_build w, @rule, get_output, @input + @config.input, @config, @config._depends, @config._odepends
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

    class CLibrarianConfiguration < NinjaConfiguration
      attr_reader :_output, :_odepends

      def initialize(*args, &block)
        @_odepends = Array.new
        super *args, &block
      end

      def flags(*args)
        _append_config :flags, args.flatten.join(' ') + ' '
      end

      def odepends(*args)
        @_odepends.concat SenseiUtils.get_outputs(args)
      end

      def output(output)
        @_output = output
      end
    end

    class CLibrarianBuilder < RuleBuilder
      def initialize(rule, config, input)
        input = [input] unless input.is_a? Array
        super rule, config, input
      end

      def get_output_name(input)
        input.convert('.o', :packagebuild)
      end

      def get_output
        @config._output
      end

      def write_ninja(w)
        write_build w, @rule, get_output, @input, @config
      end
    end

    class CLibrarian < Rule
      def initialize(path)
        super() do
          description "AR $out"
          command "#{path} $flags cr $out $in"
        end
      end

      def create_config(*args, &block)
        CLibrarianConfiguration.new *args, &block
      end

      def create_builder(rule, config, input)
        CLibrarianBuilder.new rule, config, input
      end
    end
  end
end
