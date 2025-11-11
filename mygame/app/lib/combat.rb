# never instantiated
class Combat
  def self.resolve_attack(attacker, defender, args)
    aname = attacker.name
    dname = defender.name
    # simple attack logic
    base_attack_roll = args.state.rng.d20
    to_hit = 5
    attack_roll = base_attack_roll
    # does it even hit?
    if base_attack_roll < to_hit 
      HUD.output_message args, "#{aname} attacks #{dname} but misses."
      SoundFX.play_sound(:miss, args)
      return # miss
    end
    dodge_roll = args.state.rng.d20
    if dodge_roll > attack_roll
      HUD.output_message args, "#{aname} attacks #{dname} but #{dname} dodges."
      SoundFX.play_sound(:miss, args)
      return # dodged
    end
    # hit!
    hit_location = defender.random_body_part(args)
    hit_severity = :moderate
    hit_kind = :bruise
    Trauma.inflict(defender, hit_kind)
    SoundFX.play_sound(:punch, args)
    HUD.output_message args, "#{aname} bruises #{dname}'s #{hit_location.to_s.gsub('_', ' ')}."
    # todo: inflict "shaken" effects to make the target miss some time due to receiving trauma
  end
end