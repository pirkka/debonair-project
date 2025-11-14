class Item
  attr_accessor :kind, :category, :cursed, :identified, :level, :x, :y
  attr_reader :attributes, :weight
  def initialize(kind, category, identified = false)
    @kind = kind
    @category = category
    @cursed = false
    @identified = identified
    @level = nil
    @x = nil
    @y = nil
    @attributes = []
    set_weight
  end

  def self.categories
    return [:food, :weapon, :potion, :armor, :scroll, :wand, :ring, :scroll, :amulet, :gloves, :footwear, :helmet]
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
    [255, 215, 0]
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
      return [3,0]
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
    case args.state.rng.d6
      when 1
        item = Item.new(:food_ration, :food)
        item.level = level.depth
        item.x = room.center_x
        item.y = room.center_y
        level.items << item
      when 2
        item = Potion.new(:potion_of_healing)
        item.level = level.depth
        item.x = room.center_x
        item.y = room.center_y
        level.items << item
      when 3
        item = Ring.new(Ring.kinds.sample)
        item.level = level.depth
        item.x = room.center_x
        item.y = room.center_y
        level.items << item
      when 4
        item = Weapon.randomize(level.depth, args)
        item.x = room.center_x
        item.y = room.center_y
        level.items << item
    end
    end
  end

end