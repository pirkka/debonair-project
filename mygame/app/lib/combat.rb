# never instantiated
class Combat
  def self.resolve_attack(attacker, defender, args)
    # aname, dname
    aname = attacker.class.name.downcase == 'hero' ? 'you' : attacker.species.to_s.capitalize
    dname = defender.class.name.downcase == 'hero' ? 'you' : defender.species.to_s.capitalize

    # simple attack logic
    base_attack_roll = args.state.rng.d20
    to_hit = 5
    attack_roll = base_attack_roll
    # does it even hit?
    if base_attack_roll < to_hit 
      HUD.output_message args, "#{aname} attacks #{dname} but misses."
      return # miss
    end
    dodge_roll = args.state.rng.d20
    if dodge_roll > attack_roll
      HUD.output_message args, "#{aname} attacks #{dname} but #{dname} dodge."
      return # dodged
    end
    # hit!
    hit_location = Species.humanoid_body_parts.sample
    hit_severity = :moderate
    hit_kind = :bruise
    Trauma.inflict(defender, hit_kind)
    HUD.output_message args, "#{aname} bruises #{dname}'s #{hit_location.to_s.gsub('_', ' ')}.".gsub("you's", "your")
    # todo: inflict "shaken" effects to make the target miss some time due to receiving trauma
  end
end