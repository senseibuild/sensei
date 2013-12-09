require 'sensei/compilers/gcc'
require 'sensei/compilers/binutils'

include Sensei::Compilers

PROFILE = Sensei.application.options.profile
BUILDDIR = "Build/#{PROFILE}/"

c_rules = Ruleset.new do
    if PROFILE == "Debug"
        flags "-g"
    end
end

find_package "opengl"
find_package "m"

compiler :cc => CCompiler.new("g++", c_rules)
compiler :ar => LibraryCompiler.new("ar")
compiler :ld => LinkerCompiler.new("g++")

import 'Source'
