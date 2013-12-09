require 'ostruct'

module Sensei
  class PackageReference < OpenStruct
    attr_reader :package

    def initialize(package, props)
      @package = package
      super props
    end

    def resolve
      self
    end
  end

  class LateboundPackageReference
    def initialize(name)
      @name = name
    end

    def resolve
      Sensei.application.package_manager.get @name, false
    end
  end

  class PackageManager
    def initialize
      @packages = Hash.new
    end

    def register(name, package)
      @packages[name] = package
    end

    def get(name, can_latebound = true)
      return @packages[name] if @packages.has_key? name
      return LateboundPackageReference.new name if can_latebound
      throw "Package #{name} not found"
    end
  end
end
