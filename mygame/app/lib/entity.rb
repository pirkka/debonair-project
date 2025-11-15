class Entity
  # x and y are the logical positions in the grid
  # visual_x and visual_y are used for smooth movement animations
  attr_accessor :level, :x, :y, :kind, :visual_x, :visual_y, :busy_until, :traumas, :perished, :reason_of_death, :species

  attr_accessor :enemies
  attr_accessor :allies
  attr_accessor :needs
  attr_accessor :carried_items, :worn_items, :wielded_items
  attr_accessor :behaviours
  attr_accessor :statuses
  attr_accessor :traits

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
    @wielded_items = []
    @statuses = []
    @traits = []
  end

  def add_status(status)
    @statuses << status unless @statuses.include?(status)
  end

  def remove_status(status)
    @statuses.delete(status)  
  end

  def has_status?(status)
    return @statuses.include?(status)
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
    self.traits.each do |trait|
      case trait
      when :alien
        range += 5 # aliens have a mild telepathy built in
      end
    end
    if self.worn_items
      self.worn_items.each do |item|
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

  def drop_item(item, args)
    # check that entity has item
    unless self.carried_items && self.carried_items.include?(item)
      printf "ERROR: #{self.name} tries to drop a #{item.kind.to_s.gsub('_',' ')} but doesn't have it."
      return
    end
    # check that it is not worn
    # you cannot drop worn items
    if self.worn_items && self.worn_items.include?(item)
      printf "ERROR: #{self.name} tries to drop a #{item.kind.to_s.gsub('_',' ')} but is wearing it."
      return
    end
    self.carried_items.delete(item)
    level = args.state.dungeon.levels[self.level]
    item.x = self.x
    item.y = self.y
    item.level = self.level
    level.items << item
    printf "Dropped item: %s\n" % item.kind.to_s
    SoundFX.play_sound(:drop_item, args)
    HUD.output_message(args, "#{self.name} dropped #{item.kind.to_s.gsub('_',' ')}.")
  end

  def teleport(args, x=nil, y=nil)
    level = args.state.dungeon.levels[self.level]
    if x.nil? || y.nil?
      # random teleport
      max_attempts = 100
      attempts = 0
      begin
        x = args.state.rng.rand(0...level.width)
        y = args.state.rng.rand(0...level.height)
        attempts += 1
      end while !level.is_walkable?(x,y) && attempts < max_attempts
      if attempts >= max_attempts
        HUD.output_message(args, "#{self.name} tries to teleport but fails!")
        return
      end
    end
    if level.is_walkable?(x,y)
      self.x = x
      self.y = y
      self.visual_x = x
      self.visual_y = y
      HUD.output_message(args, "#{self.name} teleports to (#{x}, #{y}).")
      SoundFX.play_sound(:teleport, args)
    else
      HUD.output_message(args, "#{self.name} tries to teleport to (#{x}, #{y}) but fails!")
    end
  end
end