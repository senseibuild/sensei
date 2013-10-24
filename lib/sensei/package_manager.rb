
module Sensei
  class PackageManager
    def initialize
      @packages = Hash.new
    end

    def register(name, package)
      @packages[name] = package
    end

    def get(name)
      @packages[name]
    end
  end
end
