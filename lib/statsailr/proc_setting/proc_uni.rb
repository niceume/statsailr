module ProcUni
  include ProcSettingModule

  source_r_file(__dir__, File.basename(__FILE__ , ".rb") + ".R")
  validate_option("data", is_a: ["SymbolR", "String"], as: "SymbolR" , required: true)

  def setting_for_var( setting )
    setting.libname = ""
    setting.func_name = "sts_uni_univariate"
    setting.main_arg_and_how_to_treat = [ "vars" , :read_as_strvec, :no_nil]
    setting.runtime_args = {"data" => param("data")}
    setting.store_result = true
    setting.print_opt = false
  end

  def setting_for_qqplot( setting )
    setting.libname = ""
    setting.func_name = "sts_uni_qqplot"
    setting.main_arg_and_how_to_treat =  [ "var" , :read_as_strvec, :allow_nil]
    setting.runtime_args = {"results" => result("var")}
    setting.store_result = false
    setting.print_opt = false
  end
end

