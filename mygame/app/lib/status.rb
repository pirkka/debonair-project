# temporal effect applied to an entity
class Status  
  attr_accessor :kind # a symbol
  attr_accessor :entity # Entity class object
  attr_accessor :created_at # world time!
  attr_accessor :duration # in world time units, nil means permanent
  
  def initialize(entity, kind, duration=nil, args)
    @kind = kind
    @duration = duration
    @entity = entity
    @created_at = args.state.kronos.world_time
    @entity.add_status(self)
  end

  def self.kinds
    [:poisoned, :confused, :blind, :deaf, :shocked]
  end

  def self.apply_statuses(entity, args)
    entity.statuses.each do |status|
      status.apply(args)
    end
  end

  def apply(args)
    if @duration
      time_now = args.state.kronos.world_time
      time_then = @created_at
      printf "Status times #{@kind} #{time_then} - #{time_now} - #{@duration}\n"
      time_elapsed = time_now - time_then
      if time_elapsed > @duration
        # status can be deleted
        @entity.statuses.delete(self)
        return
      end
    end
    case @kind
    when :poisoned
      if args.state.rng.d8 == 1
        body_part = :blood # let's call it that
        Trauma.inflict(@entity, body_part, :poison, :minor, args)
      end
    end
  end
end