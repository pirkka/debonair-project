class Effect
  attr_accessor :kind, :x, :y, :duration_remaining, :duration

  def initialize(kind, x, y, duration)
    @kind = kind
    @x = x
    @y = y
    @duration = duration
    @duration_remaining = duration # this is in world time units
  end

  # let's use interval of 0.2 time units for updates
  def update
    @duration_remaining -= 0.2   
  end
  # HSL hue cheat sheet: red=0, yellow=60, green=120, cyan=180, blue=240, magenta=300
  def color
    [0, 100, 80]
  end
end