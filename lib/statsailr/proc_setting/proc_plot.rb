module ProcPlot
  include ProcSettingModule
  add_setting_from( __dir__, "proc_common/dev_copy.rb" )
  source_r_file( __dir__, File.basename(__FILE__ , ".rb") + ".R")
  validate_option("data", is_a: ["SymbolR", "String"], as: "SymbolR" , required: true)

  def setting_for_hist( setting )
    setting.libname = ""
    setting.func_name = "sts_plot_hist"
    setting.main_arg_and_how_to_treat = [ "var" , :read_as_strvec, :no_nil]
    setting.runtime_args = {"data" => param("data")}
    setting.store_result = false
    setting.print_opt = false
    setting.plot_opt = true
  end

  def setting_for_box( setting )
    setting.libname = ""
    setting.func_name = "sts_plot_box"
    setting.main_arg_and_how_to_treat = [ "var" , :read_as_strvec, :no_nil]
    setting.runtime_args = {"data" => param("data")}
    setting.store_result = false
    setting.print_opt = false
    setting.plot_opt = true
  end

  def setting_for_scatter( setting )
    setting.libname = ""
    setting.func_name = "sts_plot_scatter"
    setting.main_arg_and_how_to_treat = [ "vars" , :read_as_strvec, :no_nil]
    setting.runtime_args = {"data" => param("data")}
    setting.store_result = false
    setting.print_opt = false
    setting.plot_opt = true
  end

end

