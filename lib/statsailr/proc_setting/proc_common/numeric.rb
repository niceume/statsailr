module NumericSetting
  include ProcSettingModule
  source_r_file(__dir__, File.basename(__FILE__ , ".rb") + ".R")

  def setting_for_factor( setting )
    setting.libname = ""
    setting.func_name = "convert_to_numeric"
    setting.main_arg_and_how_to_treat = ["vars", :read_symbols_as_strvec, :no_nil ]
    setting.runtime_args = {"data" => one_from( result("factor", "numeric"), param("data")) }
    setting.store_result = true
    setting.print_opt = false
  end
end

