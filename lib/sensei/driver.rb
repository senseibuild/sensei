require 'optparse'
require 'ostruct'
require 'pathname'
require 'fileutils'
require 'sensei/module'

module Sensei
  class Driver
    attr_reader :options

    def initialize

    end

    def run
      @options = OpenStruct.new
      @options.output_directory = Pathname.new "."
      @options.profile = "Debug"
      @options.generate = false
      @options.verbose = false

      OptionParser.new do |opts|
        opts.banner = "Usage: sensei [options]"

        opts.separator ""
        opts.separator "Options:"

        opts.on("-o", "--out [PATH]", "Output path, defaults current directory") do |path|
          FileUtils.mkpath path
          @options.output_directory = Pathname.new(File.realpath(path)).relative_path_from(Pathname.pwd)
        end

        opts.on("-p", "--profile [NAME]", "Profile name, defaults to Debug") do |name|
          @options.profile = name
        end

        opts.on("-g", "--generate [TYPE]", [:msvc], "Generate project files") do |v|
          @options.verbose = v
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options.verbose = v
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!

      mod = Module.new nil, Pathname.new('.')
      mod._write_ninja
    end
  end

  class << self
    def driver
      @driver ||= Driver.new
    end
  end
end