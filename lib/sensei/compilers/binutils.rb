require 'sensei/rule'

module Sensei
  module Compilers
    class CLibrarianConfiguration < NinjaConfiguration
      attr_reader :_output

      def initialize(*args, &block)
        super *args, &block
      end

      def flags(*args)
        _append_config :flags, args.flatten.join(' ') + ' '
      end

      def output(output)
        @_output = output
      end
    end

    class CLibrarianBuilder < RuleBuilder
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
        write_build w, @rule, get_output, @input, @config
      end
    end

    class CLibrarian < Rule
      def initialize(path)
        super() do
          description "AR $out"
          command "#{path} -o $out $flags $in"
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
