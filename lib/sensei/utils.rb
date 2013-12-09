
module Sensei
  class SenseiUtils
    def self.get_output(arg)
      arg = arg.get_output if arg.respond_to? :get_output
      arg = arg[0] if arg.is_a? Array
      arg
    end

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
end
