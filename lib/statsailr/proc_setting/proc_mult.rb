module ProcMult
  include ProcSettingModule

  source_r_file(__dir__, File.basename(__FILE__ , ".rb") + ".R")
  validate_option("data", is_a: ["SymbolR", "String"], as: "SymbolR" , required: true)

  def setting_for_aov( setting )
    setting.libname = "stats"
    setting.func_name = "aov"
    setting.main_arg_and_how_to_treat = [ "formula" , :read_as_formula, :no_nil]
    setting.runtime_args = {"data" => param("data")}
    setting.store_result = true
    setting.print_opt = "summary"
  end

  def setting_for_tukey( setting )
    setting.libname = "stats"
    setting.func_name = "TukeyHSD"
    setting.main_arg_and_how_to_treat = nil
    setting.runtime_args = {"x" => result("aov")}
    setting.store_result = false
    setting.print_opt = true
  end

  def setting_for_p_adjust( setting )
    setting.libname = ""
    setting.func_name = "sts_mult_p_adjust"
    setting.main_arg_and_how_to_treat = [ "method" , :read_as_strvec, :no_nil]
    setting.runtime_args = {"x" => result("aov")}
    setting.store_result = true
    setting.print_opt = true
  end
end

