class Potion < Item

  def initialize(kind)
    super(kind, :potion)
  end

  def self.kinds
    [
    :potion_of_healing,
    :potion_of_strength,
    :potion_of_speed,
    :potion_of_invisibility,
    :potion_of_fire_resistance,
    :potion_of_cold_resistance,
    :potion_of_poison,
    :potion_of_water_breathing,
    :potion_of_levitation,
    :potion_of_telepathy,
    :potion_of_extra_healing,
    :potion_of_teleportation
    ]
  end

  def self.masks
    [
      :pink,
      :blue,
      :yellow,
      :brown,
      :green,
      :red,
      :white,
      :black,
      :purple,
      :turquoise,
      :orange,
      :gray
    ]
  end

  def use(entity, args)
    case self.kind
    when :potion_of_healing
      effect = 0
      entity.traumas.each do |trauma|
        roll = args.state.rng.d8
        if roll >= trauma.numeric_severity
          trauma.heal_one_step
          effect += 1
        end
      end
      HUD.output_message(args, "You feel #{effect} times better!")
    when :potion_of_strength
      HUD.output_message(args, "You feel stronger!")
    when :potion_of_speed
      HUD.output_message(args, "You feel faster!")
    when :potion_of_invisibility
      HUD.output_message(args, "You become invisible!")
    end
  end

end