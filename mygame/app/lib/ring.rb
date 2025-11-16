class Ring < Item

  @@mask_index_seed = nil
  attr_accessor :usage, :max_usage

  def initialize(kind)
    super(kind, :ring)
    @usage = 0
    @max_usage = Numeric.rand(0..3000)
  end

  def self.kinds
    return [
    :ring_of_endurance, 
    # :ring_of_fire_resistance, 
    # :ring_of_cold_resistance,
    :ring_of_invisibility,
    :ring_of_protection, 
    :ring_of_strength, 
    # :ring_of_stealth, 
    :ring_of_regeneration, 
    # :ring_of_adornment,
    :ring_of_teleportation,
    :ring_of_accuracy,
    # :ring_of_night_vision,
    # :ring_of_warning,
    :ring_of_telepathy]
  end

  def self.masks
    [
      :sapphire,
      :emerald,
      :ruby,
      :diamond,
      :onyx,
      :topaz,
      :amethyst,
      :garnet,
      :opal,
      :turquoise
    ]
  end

  def use(entity, args)
    # TODO: check that we have enough fingers free to wear the ring
    # TODO: maybe have a dexterity penalty if too many rings are being worn!!!
    if entity.worn_items.include?(self)
      HUD.output_message(args, "You remove the #{self.kind.to_s.gsub('_',' ')}.")
      entity.worn_items.delete(self)
    else
      entity.worn_items << self
      HUD.output_message(args, "You wear the #{self.kind.to_s.gsub('_',' ')}.")
    end
  end

  def apply_continuous_effect(entity, args)
    case self.kind
    when :ring_of_teleportation
      roll_one = args.state.rng.d20
      if roll_one == 1
        roll_two = args.state.rng.d20
        if roll_two >= 15
          HUD.output_message(args, "The #{self.kind.to_s.gsub('_',' ')} glows brightly!")
          entity.teleport(args)
        end
      end
    when :ring_of_regeneration
      Trauma.active_traumas(entity).each do |trauma|
        if self.usage % 10 == 0 # heal one step every 10 usage ticks
          roll = args.state.rng.d12
          if roll >= trauma.numeric_severity
            HUD.output_message(args, "#{trauma.title} gets better.")
            trauma.heal_one_step
            break
          end 
        end
      end
    end 
  end
end