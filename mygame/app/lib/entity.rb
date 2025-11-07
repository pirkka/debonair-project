class Entity
  # x and y are the logical positions in the grid
  # visual_x and visual_y are used for smooth movement animations
  attr_accessor :level, :x, :y, :kind, :visual_x, :visual_y, :busy_until

  def self.kinds
    [:generic, :item, :pc, :npc, :plant, :furniture]
  end

  def initialize(x, y, kind = :generic)
    @x = x
    @y = y
    @kind = kind # item, pc, npc, etc.
    @visual_x = x
    @visual_y = y
  end
  
  def color
    return [255, 255, 255]
  end
end