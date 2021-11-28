require "pathname"
require_relative("./proc_opt_validator.rb")
require_relative("./proc_block_finalizer.rb")

module ProcSettingModule
  def self.included base
    base.extend ClassMethods
    base.instance_variable_set(:@validator, ProcOptValidator.new())
    base.instance_variable_set(:@finalizer, ProcBlockFinalizer.new())
    base.send :include, InstanceMethods
  end

  module ClassMethods
    def extend_object( extender )
      extender.instance_variable_set(:@validator, @validator)
      extender.singleton_class.__send__( :attr_accessor, :validator)
      extender.instance_variable_set(:@finalizer, @finalizer)
      extender.singleton_class.__send__( :attr_accessor, :finalizer)
      super
    end

    def source_r_file( abs_path_dir, filename)
      raise "directory path should be specified in absolute path for " +  __method__ unless Pathname.new(abs_path_dir).absolute?
      r_path = abs_path_dir + "/" + filename
      func = RBridge::create_function_call("source", { "file" => RBridge::create_strvec([r_path])} )
      RBridge::exec_function(func)
    end

    def add_setting_from( abs_path_dir, filename)
      raise "directory path should be specified in absolute path for " +  __method__ unless Pathname.new(abs_path_dir).absolute?
      require( abs_path_dir + "/" + filename )
      klass_name = File.basename( filename , ".rb").split("_").map{|elem| elem.capitalize()}.join("") + "Setting"  # e.g. dev_copy.rb => DevCopySetting
      self.include(Object.const_get(klass_name))
    end

    def validate_option(opt_key, is_a: nil, as: nil , required: true)
      @validator.rule( opt_key, is_a: is_a, as: as, required: required )
    end

    def validator
      @validator
    end

    def finalizer_enabled
      @finalizer.enabled = true
    end

    def finalizer
      @finalizer
    end
  end

  module InstanceMethods
  end
end

