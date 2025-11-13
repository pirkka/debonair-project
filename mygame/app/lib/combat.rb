# never instantiated
class Combat
  def self.resolve_attack(attacker, defender, args)
    aname = attacker.name
    dname = defender.name
    # simple attack logic
    base_attack_roll = args.state.rng.d20
    to_hit = 5
    attack_roll = base_attack_roll
    weapon_modifier = 0
    if attacker.carried_items
      attacker.carried_items.each do |item|
        if item.kind == :sword || item.kind == :axe || item.kind == :claws
          weapon_modifier = 3
        end
        if item.kind == :ring_of_accuracy
          attack_roll += 5
        end
      end
    end
    attack_roll += weapon_modifier
    # does it even hit?
    if base_attack_roll < to_hit 
      HUD.output_message args, "#{aname} attacks #{dname} but misses."
      SoundFX.play_sound(:miss, args)
      return # miss
    end
    # defender attempts to dodge
    if !attacker.invisible?
      dodge_roll = args.state.rng.d20
      if dodge_roll > attack_roll
        HUD.output_message args, "#{aname} attacks #{dname} but #{dname} dodges."
        SoundFX.play_sound(:miss, args)
        return # dodged
      end
    end
    # hit!
    hit_location = defender.random_body_part(args)
    hit_severity = self.hit_severity(attacker, defender, attack_roll, args)
    hit_kind = :bruise
    Trauma.inflict(defender, hit_location, hit_kind, hit_severity, args)
    SoundFX.play_sound(:hit, args)
    HUD.output_message args, "#{aname} bruises #{dname}'s #{hit_location.to_s.gsub('_', ' ')} #{hit_severity}ly."
    # todo: inflict "shaken" effects to make the target miss some time due to receiving trauma
    defender_dead = Trauma.determine_morbidity(defender)
    printf "Defender dead?=: %s, Defender wound count: %d\n" % [defender_dead.to_s, defender.traumas.size]
    if defender_dead
      HUD.output_message args, "#{dname} has died from their injuries!"
      if defender == args.state.run.hero
        args.state.scene = :game_over
        args.state.hero.perished = true
        args.state.hero.reason_of_death = " combat against #{aname}"
        return
      else
        # remove defender from level
        level = args.state.dungeon.levels[defender.level]
        level.entities.delete(defender)
      end
    end
  end

  def self.hit_severity(attacker, defender, attack_roll, args)
    severity_modifier = 0
    if attacker.carried_items
      attacker.carried_items.each do |item|
        if item.kind == :ring_of_strength
          severity_modifier += 5
        end
      end
    end
    if attack_roll == 20
      # natural 20, critical hit
      severity_modifier += 5
    end
    severity_roll = args.state.rng.d20 + severity_modifier
    case severity_roll
    when 1..8
      return :minor
    when 9..14
      return :moderate
    when 15..18
      return :severe
    when 19..Float::INFINITY
      return :critical
    end
  end
end