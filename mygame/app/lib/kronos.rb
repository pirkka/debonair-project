class Action
  # kinds
  # execute_time
  # recovery_time 
  attr_accessor :kind, :execute_time, :recovery_time
  def initialize kind, execute_time, recovery_time, target=nil
    @kind = kind
    @execute_time = execute_time
    @recovery_time = recovery_time
    @target = target
  end

  def self.kinds
    return [:move_up, :move_down, :move_left, :move_right, :wait, :special_ability]
  end
end

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
    # every entity needs to be busy most of the time. even idling.
    # due to performance reasons, we only advance time on the current level
    # and assume other levels are frozen.
    # this is classic retro gameplay, it's ok. 
    # we might change it so that offscreen levels also advance time slowly later.
    # or at least the levels +-1 from the current level are active
    relevant_entities = []
    relevant_entities += args.state.dungeon.levels[args.state.hero.level].entities

    min_busy_until = nil
    idle_entity = nil
    relevant_entities.each do |entity|
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