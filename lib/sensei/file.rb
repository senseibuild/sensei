require 'pathname'

module Sensei
  class SenseiFile
    attr_reader :project, :type, :path

    def self.file(type, path)
      SenseiFile.new nil, type, path
    end

    def self.full(path)
      SenseiFile.new nil, :full, path
    end

    def self.root(path)
      SenseiFile.new nil, :root, path
    end

    def self.build(path)
      SenseiFile.new nil, :build, path
    end

    def initialize(project, type, path)
      @project = project
      @type = type
      @path = path
      @path = Pathname.new @path if @path.is_a? String
    end

    def to_build
      if @type == :build or @type == :full then
        path = @path
      elsif @type == :root then
        path = @path.relative_path_from Sensei.driver.options.output_directory
      elsif @type == :project or @type == :module then
        path = (@project.path + @path).relative_path_from Sensei.driver.options.output_directory
      elsif @type == :projectbuild then
        path = @project.path + @path
      end

      SenseiFile.new @project, :build, path
    end

    def change_extension(ext)
      SenseiFile.new @project, @type, path.sub_ext(ext)
    end

    def change_type(type)
      SenseiFile.new @project, type, @path
    end

    def convert(ext, type)
      SenseiFile.new @project, type, path.sub_ext(ext)
    end

    def addconvert(ext, type)
      SenseiFile.new @project, type, path.sub_ext(path.extname + ext)
    end

    def rebase(base)
      SenseiFile.new base.project, base.type, base.path + @path
    end

    def +(path)
      SenseiFile.new @project, @type, @path + path
    end

    def to_path
      @path.to_s
    end

    def to_s
      @path.to_s
    end

    def mkbasepath
      # TODO: Ninja should do this
      (Sensei.driver.options.output_directory + to_build.path.dirname).mkpath
    end
  end
end
