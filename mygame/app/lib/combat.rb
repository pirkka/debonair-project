# never instantiated
class Combat

  def self.distance_modifier(attacker, defender, args)
    dx = (attacker.x - defender.x).abs
    dy = (attacker.y - defender.y).abs
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance <= 3
      return 2
    elsif distance <= 6
      return 0
    elsif distance <= 10
      return -2
    else
      return -4
    end
  end

  def self.ranged_to_hit_probability(attacker, defender, item, args)
    dx = (attacker.x - defender.x).abs
    dy = (attacker.y - defender.y).abs
    distance = Math.sqrt(dx * dx + dy * dy)
    if distance <= 3
      return 0.8
    elsif distance <= 6
      return 0.6
    elsif distance <= 10
      return 0.4
    else
      return 0.2
    end
  end

  def self.resolve_ranged_attack(attacker, item, defender, args)
    aname = attacker.name
    dname = defender.name
    inaccuracy_penalty = 0
    case item.kind
    when :revolver
      inaccuracy_penalty = 0    
    when :crossbow
      inaccuracy_penalty = 1
    when :bow
      inaccuracy_penalty = 2
    when :sling
      inaccuracy_penalty = 3
    when :dagger, :spear, :shuriken
      inaccuracy_penalty = 4
    else
      inaccuracy_penalty = 5
    end
    base_attack_roll = args.state.rng.d20
    attack_roll = base_attack_roll - inaccuracy_penalty
    to_hit = 12 # should depend on size, speed and distance of the target! TODO
    to_hit += self.distance_modifier(attacker, defender, args)
    if base_attack_roll == 1
      fumble_roll = args.state.rng.d10
      if fumble_roll < 3
        HUD.output_message args, "#{aname} attempts to attack but fumbles!"
        SoundFX.play_sound(:fumble, args)
        item.break_check(args)
        return
      end
    end
    attack_roll += Combat.role_bonus(attacker, args)
    # species bonus
    if attacker.species == :elf || attacker.species == :dark_elf
      attack_roll += 2
    end
    # items that affect accuracy
    if attacker.worn_items
      attacker.worn_items.each do |item|
        if item.kind == :ring_of_accuracy
          attack_roll += 5
        end
        # TODO: helmet that decreases accuracy 
      end
    end
    if defender.has_status?(:shocked)
      to_hit -= 5
    end
    # we are done with the modifiers
    printf "Ranged attack roll: %d vs to hit %d (base roll %d, inaccuracy penalty %d)\n" % [attack_roll, to_hit, base_attack_roll, inaccuracy_penalty]
    # does it even hit?
    if attack_roll < to_hit 
      HUD.output_message args, "#{aname} shoots #{item.title(args)} at #{dname} but misses."
      SoundFX.play_sound(:miss, args)
      return # miss
    end
    # hit!
    HUD.output_message args, "#{aname} shoots #{item.title(args)} at #{dname} and hits!"
    body_part = defender.random_body_part(args)
    hit_severity = self.hit_severity(attacker, defender, attack_roll, args)
    hit_kind = item.hit_kind(args)
    Trauma.inflict(defender, body_part, hit_kind, hit_severity, args)
    SoundFX.play_sound(:hit, args)
    verb = "#{hit_kind}s"
    HUD.output_message args, "#{aname} #{verb} #{dname}'s #{body_part.to_s.gsub('_', ' ')} #{hit_severity}ly."
    attacker.apply_exhaustion(0.01, args) if attacker == args.state.hero
    self.resolve_defender_on_hit_effects(defender, args)
  end

  def self.resolve_attack(attacker, defender, args)
    aname = attacker.name
    dname = defender.name
    # simple attack logic
    base_attack_roll = args.state.rng.d20
    to_hit = 5
    attack_roll = base_attack_roll
    if base_attack_roll == 1
      base_attack_roll = args.state.rng.d10
      if base_attack_roll < 3
        HUD.output_message args, "#{aname} attempts to attack but fumbles!"
        SoundFX.play_sound(:fumble, args)
        attacker.wielded_items.each do |item|
          if item.category == :weapon
            item.break_check(args)
            break
          end
        end
        return
      end
    end
    if defender.has_status?(:shocked)
      to_hit -= 10
    end
    weapon_modifier = 0
    if attacker.wielded_items
      attacker.wielded_items.each do |item|
        if item.category == :weapon
          weapon_modifier = 3 # base for all weapons
        end
        if item.attributes.include?(:fine)
          weapon_modifier += 2
        elsif item.attributes.include?(:rusty) 
          weapon_modifier -= 2
        elsif item.attributes.include?(:crude)
          weapon_modifier -= 1
        elsif item.attributes.include?(:masterwork)
          weapon_modifier += 4
        elsif item.attributes.include?(:legendary)
          weapon_modifier += 6
        elsif item.attributes.include?(:cursed)
          weapon_modifier -= 3
        elsif item.attributes.include?(:broken)
          weapon_modifier -= 4
        end
      end
    end
    if attacker.worn_items
      attacker.worn_items.each do |item|
        if item.kind == :ring_of_accuracy
          attack_roll += 5
        end
      end
    end
    attack_roll += weapon_modifier
    attack_roll += Combat.role_bonus(attacker, args)
    # does it even hit?
    if base_attack_roll < to_hit 
      HUD.output_message args, "#{aname} attacks #{dname} but misses."
      SoundFX.play_sound(:miss, args)
      return # miss
    end
    # defender attempts to dodge
    if !attacker.invisible? && !defender.has_status?(:shocked)
      dodge_roll = args.state.rng.d20
      dodge_roll -= 3 # just to make it a bit less likely to dodge  
      if dodge_roll > attack_roll
        HUD.output_message args, "#{aname} attacks #{dname} but #{dname} dodges."
        SoundFX.play_sound(:miss, args)
        return # dodged
      end
    end
    # hit!
    body_part = defender.random_body_part(args)
    hit_severity = self.hit_severity(attacker, defender, attack_roll, args)
    hit_kind = attacker.hit_kind(args)
    Trauma.inflict(defender, body_part, hit_kind, hit_severity, args)
    SoundFX.play_sound(:hit, args)
    verb = "#{hit_kind}s"
    HUD.output_message args, "#{aname} #{verb} #{dname}'s #{body_part.to_s.gsub('_', ' ')} #{hit_severity}ly."
    attacker.apply_exhaustion(0.05, args) if attacker == args.state.hero
    self.resolve_defender_on_hit_effects(defender, args)
  end

  def self.resolve_defender_on_hit_effects(defender, args)
    aname = args.state.run.hero.name
    dname = defender.name
    # check for shock or death
    defender_shocked = Trauma.determine_shock(defender)
    if defender_shocked
      Status.new(defender, :shocked, nil, args)
      defender.drop_wielded_items(args)
      HUD.output_message args, "#{dname} is in shock from trauma!"
    end
    # todo: inflict "shaken" effects to make the target miss some time due to receiving trauma
    defender_dead = Trauma.determine_morbidity(defender)
    printf "Defender dead?=: %s, Defender wound count: %d\n" % [defender_dead.to_s, defender.traumas.size]
    if defender_dead
      if defender.undead?
        HUD.output_message args, "#{dname} has been destroyed!"
      else
        HUD.output_message args, "#{dname} has died!"
      end
      if defender == args.state.run.hero
        HUD.output_message args, "Press A to continue..."
        args.state.hero.perished = true
        args.state.hero.reason_of_death = "in combat against #{aname}"
        return
      else
        SoundFX.play_sound(:npc_death, args)
        defender.drop_all_items(args)
        level = args.state.dungeon.levels[defender.depth]
        level.entities.delete(defender)
      end
    else
      if defender == args.state.run.hero
        GUI.flash_screen(:red, args)
        SoundFX.play_sound(:hero_hurt, args)
      else
        SoundFX.play_sound(:npc_hurt, args)
      end
    end    
  end

  def self.hit_severity(attacker, defender, attack_roll, args)
    severity_modifier = 0
    weapon_modifier = 0
    if attacker.wielded_items
      attacker.wielded_items.each do |item|
        if item.category == :weapon
          weapon_modifier = 3 # base for all weapons
        end
        if item.attributes.include?(:fine)
          weapon_modifier += 2
        elsif item.attributes.include?(:rusty) 
          weapon_modifier -= 2
        elsif item.attributes.include?(:crude)
          weapon_modifier -= 1
        elsif item.attributes.include?(:masterwork)
          weapon_modifier += 4
        elsif item.attributes.include?(:legendary)
          weapon_modifier += 6
        elsif item.attributes.include?(:cursed)
          weapon_modifier -= 3
        elsif item.attributes.include?(:broken)
          weapon_modifier -= 4
        end
      end
    end
    severity_modifier += weapon_modifier
    if attacker.worn_items
      attacker.worn_items.each do |item|
        if item.kind == :ring_of_strength
          severity_modifier += 5
        end
      end
    end
    if attack_roll == 20
      # natural 20, critical hit
      severity_modifier += 5
    end
    # defender's items
    if defender.worn_items
      defender.worn_items.each do |item|
        if item.kind == :ring_of_protection
          severity_modifier -= 5
        end
      end
    end
    # attacker strong status
    if attacker.has_status?(:strenghtened)
      severity_modifier += 5
    end
    # roll for severity
    severity_roll = args.state.rng.d20 + severity_modifier
    case severity_roll
    when 1..10
      return :minor
    when 11..15
      return :moderate
    when 16..19
      return :severe
    when 20..Float::INFINITY
      return :critical
    end
  end

  def self.role_bonus(character, args)
    if args.state.hero != character
      return 0
    end
    case character.role
    when :warrior, :samurai, :ninja
      return 3
    when :rogue
      return 2
    when :tourist, :monk, :detective
      return -1
    when :mage, :druid, :archeologist
      return -2
    else
      return 0
    end
  end
end