require 'sensei/compilers/c_cxx'

include Sensei::Compilers

PROFILE = Sensei.application.options.profile
BUILDDIR = "Build/#{PROFILE}/"

c_rules = Ruleset.new do
    if PROFILE == "Debug"
        flags "-g"
    end
end

compiler :cc => CCompiler.new("g++", c_rules)

import 'Source'
