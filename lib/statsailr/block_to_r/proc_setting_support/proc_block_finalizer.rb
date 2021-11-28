class ProcBlockFinalizer
  attr :enabled, true
  def initialize
    @enabled = false
  end

  def enabled?
    return @enabled
  end
end
