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
  attr_reader :world_time
  
  def self.initialize args
    args.state.kronos = Kronos.new
  end

  def initialize
    @world_time = 0 # simulation seconds since game start
    @continuous_effects_applied_until = 0
    @level_effects_applied_until = 0
  end

  def spend_time entity, seconds, args
    entity.busy_until = @world_time + seconds
  end

  def advance_time args
    if args.state.game_over
      return
    end
    # every entity needs to be busy most of the time. even idling.
    # due to performance reasons, we only advance time on the current level
    # and assume other levels are frozen.
    # this is classic retro gameplay, it's ok. 
    # we might change it so that offscreen levels also advance time slowly later.
    # or at least the levels +-1 from the current level are active
    relevant_entities = []
    relevant_entities += args.state.dungeon.levels[args.state.hero.depth].entities

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
    if self.should_continous_effects_be_applied?
      self.apply_continuous_effects args
    end
    if self.should_level_effects_be_applied?
      self.apply_effects args
    end
    idle_entity.take_action args
    HUD.mark_minimap_stale
  end

  def should_level_effects_be_applied?
    return @world_time > @level_effects_applied_until
  end

  # these are level effects like fire, magic etc. that affect tiles and decay over time
  def apply_effects args
    level = Utils.level(args)
    level.apply_effects args
    @level_effects_applied_until = @world_time + 0.2
  end
    
  def should_continous_effects_be_applied?
    return @world_time > @continuous_effects_applied_until
  end
  
  # these effects are applied once every second of world time
  def apply_continuous_effects args
    # apply continuous effects like hunger, ring depletion, etc.
    hero = args.state.hero
    # hunger
    hero.apply_hunger args
    # shock recovery
    Utils.level(args).entities.each do |entity|
      entity.recover_shock args
      Status.apply_statuses entity, args
    end
    
    # worn rings
    hero.worn_items.each do |item|
      if item.category == :ring
        item.usage += 1
        if item.usage >= item.max_usage
          HUD.output_message args, "Your #{item.title(args)} crumbles to dust!"
          hero.worn_items.delete(item)
          hero.carried_items.delete(item)
        end
        item.apply_continuous_effect(hero, args)
      end
    end
    @continuous_effects_applied_until = @world_time + 1 # apply once every 1 world time unit
  end 
end