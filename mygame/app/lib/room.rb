class Room
  attr_accessor :x, :y, :w, :h
  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end

  def center_x
    return (x + (w / 2)).to_i
  end
  
  def center_y
    return (y + (h / 2)).to_i
  end

  def intersects?(other)
    return !(@x + @w < other.x || other.x + other.w < @x ||
             @y + @h < other.y || other.y + other.h < @y)
  end

end

