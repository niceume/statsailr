class GramNode
  attr :e1, :e2, :e3, :type
  def initialize(type, e1, e2 = nil, e3=nil)
    @type = type
    @e1 = e1
    @e2 = e2
    @e3 = e3
  end
end
