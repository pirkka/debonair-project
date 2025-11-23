class Item
  attr_accessor :kind, :category, :cursed, :identified, :depth, :x, :y
  attr_reader :attributes, :weight, :traits
  def initialize(kind, category, identified = false)
    @kind = kind
    @category = category
    @cursed = false
    @identified = identified
    @depth = nil
    @x = nil
    @y = nil
    @attributes = []
    @traits = []
    set_weight
  end

  def self.categories
    return [:food, :weapon, :potion, :armor, :scroll, :wand, :ring, :scroll, :amulet, :gloves, :footwear, :helmet, :portable_light]
  end

  def set_weight # grams
    case @category
    when :food
      @weight = 0.4 
    when :weapon
      @weight = 1.0
    when :potion
      @weight = 0.2
    when :armor
      @weight = 4.0
    when :scroll
      @weight = 0.2
    when :wand
      @weight = 0.1
    when :ring
      @weight = 0.02
    when :amulet
      @weight = 0.2
    when :gloves
      @weight = 0.4
    when :footwear
      @weight = 0.4
    when :helmet
      @weight = 0.3
    else
      @weight = 0.4
    end
  end

  def add_attribute(attribute)
    @attributes << attribute unless @attributes.include?(attribute)
  end

  def remove_attribute(attribute)
    @attributes.delete(attribute)
  end

  def color
    [56, 100, 100]
  end

  def title
    "#{self.attributes.join(' ')} #{self.kind.to_s.gsub('_',' ')}".gsub('  ',' ').trim
  end

  def c 
    # character representation from the sprite sheet
    case @category
    when :food
      return [5,2]
    when :weapon
      return [9,2]
    when :potion
      return [1,2]
    when :armor
      return [2,0]
    when :scroll
      return [15,3]
    when :wand
      return [4,0]
    when :ring
      return [13,3]
    when :amulet
      return [15,0]
    when :gloves
      return [7,0]
    when :footwear
      return [8,0]
    when :helmet
      return [9,0]
    else
      return [10,0] # unknown
    end
  end

  def self.populate_dungeon(dungeon, args)
    for level in dungeon.levels
      self.populate_level(level, args)
    end
  end

  def self.populate_level(level, args)
    level.rooms.each do |room|
      case args.state.rng.d12
        when 1
          item = Food.new(:food_ration, args)
          item.depth = level.depth
          item.x = room.center_x
          item.y = room.center_y
          level.items << item
        when 2
          item = Potion.randomize(level.depth, args)
          item.depth = level.depth
          item.x = room.center_x
          item.y = room.center_y
          level.items << item
        when 3
          if args.state.rng.d6 < 4
            item = Ring.new(Ring.kinds.sample)
            item.depth = level.depth
            item.x = room.center_x
            item.y = room.center_y
            level.items << item
          else
            item = Potion.new(:potion_of_healing)
            item.depth = level.depth
            item.x = room.center_x
            item.y = room.center_y
            level.items << item
          end
        when 4
          item = Weapon.randomize(level.depth, args)
          item.x = room.center_x
          item.y = room.center_y
          level.items << item
        when 5
          item = Scroll.randomize(level.depth, args)
          item.depth = level.depth
          item.x = room.center_x
          item.y = room.center_y
          level.items << item
      end
    end
  end

  # weight in kilograms
  def self.carried_weight(entity)
    total_weight = 0.0
    if entity.carried_items
      entity.carried_items.each do |item|
        total_weight += item.weight
      end
    end
    return total_weight
  end

  # base carrying capacity - how many kilograms can be carried without encumbrance
  # hauling capacity - maximum load that can be carried, only few squares at a time
  def self.base_carrying_capacity(entity)
    base_capacity = 10.0                          
    case entity.species 
    when :dwarf
      base_capacity += 20.0
    when :troll
      base_capacity += 40.0
    when :gnome
      base_capacity -= 5.0
    when :halfling, :goblin, :duck
      base_capacity -= 3.0
    when :dark_elf, :elf
      base_capacity -= 1.0
    end
    return base_capacity
  end

  def self.maximum_carrying_capacity(entity)
    return Item.base_carrying_capacity(entity) * 5.0
  end

  def self.encumbrance_factor(entity, args)
    carrying_capacity = Item.base_carrying_capacity(entity)
    total_weight = Item.carried_weight(entity)
    if total_weight <= carrying_capacity
      return 1.0
    elsif total_weight <= carrying_capacity * 1.5
      return 1.2 # light encumbrance
    elsif total_weight <= carrying_capacity * 2.0
      return 2.0  # medium encumbrance
    elsif total_weight <= carrying_capacity * 3.0
      return 6.0 # heavy encumbrance
    elsif total_weight <= carrying_capacity * 4.0
      return 8.0 # heavy encumbrance
    elsif total_weight <= Item.maximum_carrying_capacity(entity)  
      # heavy encumbrance
      return 12.0
    end
  end

  def use(user, args)
    # default: do nothing
  end
end