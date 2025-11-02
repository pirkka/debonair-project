class Architect
  # singleton class that creates the dungeon and populates it with entities
  def self.instance
    @instance ||= Architect.new
  end

  def setup(settings)
    @settings = settings
    @settings.levels ||= 10
    @settings.level_width ||= 80
    @settings.level_height ||= 50
    
  end

  def architect_dungeon(state)
    create_dungeon(state)
    populate_entities(state)
  end

  def create_dungeon(state)
    # Code to create the dungeon layout
  end

  def populate_entities(state)
    # Code to add entities to the dungeon
  end
end