module ProcReg
  include ProcSettingModule

  add_setting_from( __dir__, "proc_common/factor.rb" )
  validate_option("data", is_a: ["SymbolR", "String"], as: "SymbolR" , required: true)

  def setting_for_lm( setting )
    setting.libname = "stats"
    setting.func_name = "lm"
    setting.main_arg_and_how_to_treat = ["formula", :read_as_formula, :no_nil ]
    setting.runtime_args = {"data" => one_from( result("factor", "numeric"), param("data")) }
    setting.store_result = true
    setting.print_opt = "summary"
  end
end


