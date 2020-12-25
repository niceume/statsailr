module DevCopySetting
  include ProcSettingModule
  source_r_file(__dir__, File.basename(__FILE__ , ".rb") + ".R")

  def setting_for_dev_copy( setting )
    setting.libname = ""
    setting.func_name = "sts_dev_copy"
    setting.main_arg_and_how_to_treat = [ "device" , :read_as_symbol , :allow_nil ]
    setting.runtime_args = {}
    setting.store_result = false
    setting.print_opt = false
  end
end

