module ProcPrint  
  include ProcSettingModule

  source_r_file(__dir__, File.basename(__FILE__ , ".rb") + ".R")
  validate_option("data", is_a: ["SymbolR", "String"], as: "SymbolR" , required: true)

  def setting_for_head( setting )
    setting.libname = "utils"
    setting.func_name = "head"
    setting.main_arg_and_how_to_treat = [ "n", :read_as_intvec, :allow_nil ]
    setting.runtime_args = { "x" => param("data")}
    setting.store_result = true
    setting.print_opt = true
  end

  def setting_for_tail( setting )
    setting.libname = "utils"
    setting.func_name = "tail"
    setting.main_arg_and_how_to_treat = [ "n", :read_as_intvec, :allow_nil ]
    setting.runtime_args = { "x" => param("data") }
    setting.store_result = true
    setting.print_opt = true
  end

  def setting_for_nth( setting )
    setting.libname = ""
    setting.func_name = "sts_print_nth"
    setting.main_arg_and_how_to_treat = [ "positions", :read_as_strvec, :allow_nil ]
    setting.runtime_args = { "x" => param("data") }
    setting.store_result = true
    setting.print_opt = true
  end

  def setting_for_random( setting )
    setting.libname = ""
    setting.func_name = "sts_print_random"
    setting.main_arg_and_how_to_treat = [ "n", :read_as_intvec, :allow_nil ]
    setting.runtime_args = { "x" => param("data") }
    setting.store_result = true
    setting.print_opt = true
  end
end
