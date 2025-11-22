class Entity
  # x and y are the logical positions in the grid
  # visual_x and visual_y are used for smooth movement animations
  attr_accessor :depth, :x, :y, :kind, :visual_x, :visual_y, :busy_until, :traumas, :perished, :reason_of_death, :species

  attr_accessor :enemies
  attr_accessor :allies
  attr_accessor :needs
  attr_accessor :carried_items, :worn_items, :wielded_items
  attr_accessor :behaviours
  attr_accessor :statuses
  attr_accessor :traits
  attr_accessor :hands

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
    @hands = [:right, :left] # in order of preference
  end

  def is_hostile_to?(other_entity)
    return @enemies.include?(other_entity)
  end

  def become_hostile_to(other_entity)
    @enemies << other_entity unless @enemies.include?(other_entity)
  end
    
  def is_allied_to?(other_entity)
    return @allies.include?(other_entity)
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
    return Utils.line_of_sight?(self.x, self.y, other_entity.x, other_entity.y, args.state.dungeon.levels[self.depth])
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
    level = args.state.dungeon.levels[self.depth]
    item.x = self.x
    item.y = self.y
    item.depth = self.depth
    level.items << item
    printf "Dropped item: %s\n" % item.kind.to_s
    SoundFX.play_sound(:drop_item, args)
    HUD.output_message(args, "#{self.name} dropped #{item.kind.to_s.gsub('_',' ')}.")
  end

  def teleport(args, x=nil, y=nil)
    level = args.state.dungeon.levels[self.depth]
    if x.nil? || y.nil?
      # random teleport
      max_attempts = 100
      attempts = 0
      begin
        x = args.state.rng.nxt_int(0, level.width-1)
        y = args.state.rng.nxt_int(0, level.height-1)
        attempts += 1
        printf "Teleport attempt %d to (%d, %d)\n" % [attempts, x, y]
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
      SoundFX.play_sound(:teleport, args)
    end
  end

  def slowed_in_water?
    slowed = true
    if self.species == :grid_bug
      slowed = false
    end
    return slowed
  end 

  def walking_sound tile, args
    return
  end
end