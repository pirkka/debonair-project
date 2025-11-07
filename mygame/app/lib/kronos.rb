class Kronos
  # the timekeeper
  @world_time = 0 # in simulation seconds since game start
  attr_reader :world_time
  
  def self.initialize args
    args.state.kronos = Kronos.new
  end

  def initialize
    @world_time = 0 # simulation seconds since game start
  end

  def spend_time entity, seconds, args
    entity.busy_until = @world_time + seconds
  end

  def advance_time args
    # note: currently only the entities in the current level are considered
    # we might change this pretty soon
    # every entity needs to be busy most of the time. even idling.
    all_entities = []
    for level in args.state.dungeon.levels
      all_entities += level.entities
    end
    min_busy_until = nil
    idle_entity = nil
    all_entities.each do |entity|
      min_busy_until ||= entity.busy_until || 0
      this_busy_until = entity.busy_until || 0
      if this_busy_until <= min_busy_until 
        min_busy_until = this_busy_until
        idle_entity = entity
      end
    end
    @world_time = min_busy_until unless min_busy_until < @world_time # time cannot go backwards
    idle_entity.take_action args 
  end
end