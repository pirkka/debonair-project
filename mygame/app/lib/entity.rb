class Entity
  # x and y are the logical positions in the grid
  # visual_x and visual_y are used for smooth movement animations
  attr_accessor :level, :x, :y, :kind, :visual_x, :visual_y, :busy_until, :traumas, :perished, :reason_of_death, :species

  attr_accessor :enemies
  attr_accessor :allies
  attr_accessor :needs
  attr_accessor :carried_items, :worn_items
  attr_accessor :behaviours

  def self.kinds
    [:generic, :item, :pc, :npc, :plant, :furniture]
  end

  def initialize(x, y, kind = :generic)
    @x = x
    @y = y
    @kind = kind # item, pc, npc, etc.
    @visual_x = x
    @visual_y = y
    @traumas = []
    @enemies = []
    @allies = []
    @needs = []
    @perished = false
    @reason_of_death = nil
    @carried_items = []
    @worn_items = []
    @behaviours = []
  end
  
  def color
    return [255, 255, 255]
  end

  def random_body_part(args)
    parts = body_parts
    parts[args.state.rng.rand(parts.length)]
  end

  def body_parts
    case @species
    when :grid_bug
      return Species.bug_body_parts
    when :rat
      return Species.mammal_body_parts
    else
      return Species.humanoid_body_parts
    end
  end

  def telepathy_range
    range = 0
    case @species
    when :grid_bug
      range += 5
    end
    if self.carried_items
      self.carried_items.each do |item|
        if item.kind == :ring_of_telepathy
          range += 20
        end
      end
    end
    return range
  end

  def invisible?
    invisibility = false
    if self.worn_items
      self.worn_items.each do |item|
        if item.kind == :cloak_of_invisibility || item.kind == :ring_of_invisibility
          invisibility = true
        end
      end
    end
    return invisibility
  end

  def sees?(other_entity, args)
    dx = other_entity.x - self.x
    dy = other_entity.y - self.y
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance > 15
      return false
    end
    if other_entity.invisible?
      return false
    end
    return Utils.line_of_sight?(self.x, self.y, other_entity.x, other_entity.y, args.state.dungeon.levels[self.level])
  end

  def use_item(item, args)
    # check that entity has item
    unless self.carried_items && self.carried_items.include?(item)
      printf "ERROR: #{self.name} tries to use a #{item.kind.to_s.gsub('_',' ')} but doesn't have it."
      return
    end
    item.use(self, args)
  end
end