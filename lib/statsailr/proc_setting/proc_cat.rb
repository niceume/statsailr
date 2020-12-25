module ProcCat
  include ProcSettingModule

  source_r_file( __dir__, File.basename(__FILE__ , ".rb") + ".R")
  validate_option("data", is_a: ["SymbolR", "String"], as: "SymbolR" , required: true)

  def setting_for_table( setting )
    setting.libname = ""
    setting.func_name = "sts_cat_table"
    setting.main_arg_and_how_to_treat = ["vars", :read_as_strvec, :no_nil]
    setting.runtime_args = {"data" => param("data") }
    setting.store_result = true
    setting.print_opt = false
  end

  def setting_for_xtabs( setting )
    setting.libname = "stats"
    setting.func_name = "xtabs"
    setting.main_arg_and_how_to_treat = ["formula", :read_as_formula, :no_nil]
    setting.runtime_args = {"data" => param("data") }
    setting.store_result = true
    setting.print_opt = true
  end

  def setting_for_fisher_test( setting )
    setting.libname = "stats"
    setting.func_name = "fisher.test"
    setting.main_arg_and_how_to_treat = nil
    setting.runtime_args = {"x" => one_from( result("table"), result("xtabs") ) }
    setting.store_result = true
    setting.print_opt = true
  end

  def setting_for_chisq_test( setting )
    setting.libname = "stats"
    setting.func_name = "chisq.test"
    setting.main_arg_and_how_to_treat = nil
    setting.runtime_args = {"x" => one_from( result("table"), result("xtabs") ) }
    setting.store_result = true
    setting.print_opt = true
  end
end

