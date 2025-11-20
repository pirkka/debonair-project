class Trauma
  attr_reader :kind, :category, :treatments, :body_part, :last_treated, :severity, :entity
  def initialize(kind, body_part, severity, entity)
    @kind = kind
    @category = Trauma.kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    @treatments = []
    @body_part = body_part
    @severity = severity
    @last_treated = nil # simulation time when applied
    @entity = entity
  end

  def self.categories
    [:physical, :mental, :emotional]
  end

  def self.severities
    [:healed, :minor, :moderate, :severe, :critical]
  end

  def self.treatments
    [:none, :harmful, :useless, :basic, :professional, :magical, :miraculous]
  end

  def self.kinds
    {
      physical: [:cut, :bruise, :fracture, :burn, :cold, :sprain, :bite, :sting, :puncture, :internal_injury],
      mental: [:concussion, :stress],
      emotional: [:grief, :anxiety, :fear, :depression]
    }
  end

  def heal_one_step
    case @severity
    when :critical
      @severity = :severe
    when :severe
      @severity = :moderate
    when :moderate
      @severity = :minor
    else :minor
      @severity = :healed
    end
    # check for shock recovery
    if entity.has_status?(:shock)
      still_shocked = Trauma.determine_shock(entity)  
      unless still_shocked
        entity.remove_status(:shock)
      end
    end
  end

  def numeric_severity
    case @severity
    when :healed
      return 0
    when :minor
      return 1
    when :moderate
      return 2
    when :severe
      return 4
    when :critical
      return 8
    else
      return 0
    end
  end

  def self.inflict(entity, body_part, kind, severity, args)
    category = kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    raise 'Unknown trauma kind' unless category
    trauma = Trauma.new(kind, body_part, severity, entity)
    trauma.instance_variable_set(:@body_part, body_part)  
    entity.traumas << trauma
    entity.increase_need(:avoid_being_hit)
    printf "Inflicted #{kind} trauma to #{entity.class} at #{body_part}. Has now #{entity.traumas.size} traumas.\n"
    return trauma
  end

  def self.determine_shock(entity)
    shock_score = 0
    shock_threshold = 3
    entity.traumas.each do |trauma|
      case trauma.severity
      when :minor
        shock_score += 0
      when :moderate
        shock_score += 1
      when :severe
        shock_score += 2
      when :critical
        shock_score += 3
      end
    end
    if shock_score >= shock_threshold
      return true
    else
      return false
    end
  end

  def self.determine_morbidity(entity)
    printf "Determining morbidity for entity with %d traumas.\n" % [entity.traumas.size]
    death_score = 0
    death_threshold = 10
    entity.traumas.each do |trauma|     
      case trauma.severity
      when :minor
        death_score += 0
      when :moderate
        death_score += 2
      when :severe
        death_score += 4
      when :critical
        death_score += 6
      end    
    end
    if death_score >= death_threshold
      return true
    else
      return false
    end
  end

  def self.body_parts_counted_for_death
    [:head, :torso, :heart, :lungs, :brain, :spine, :abdomen, :forehead, :top_of_skull, :back_of_skull, :colon, :intestines, :stomach, :genitals, :left_temple, :right_temple, :thorax, :eyes, :left_eye, :right_eye, :right_calf, :left_calf, :right_thigh, :left_thigh]
  end

  def self.active_traumas(entity)
    return entity.traumas.select { |trauma| trauma.severity != :healed }
  end

  def title
    "#{@severity.to_s.capitalize} #{@kind.to_s.gsub('_',' ')} on #{@body_part.to_s.gsub('_',' ')}"
  end

  def self.walking_speed_modifier(entity)
    speed_modifier = 1.0
    active_traumas(entity).each do |trauma|
      case trauma.body_part
      when :left_leg, :right_leg, :left_knee, :right_knee, :left_foot, :right_foot, :left_hip, :right_hip, :left_thigh, :right_thigh, :left_calf, :right_calf, :toes_of_left_foot, :toes_of_right_foot
        case trauma.severity
        when :minor
          speed_modifier -= 0.05
        when :moderate
          speed_modifier -= 0.1
        when :severe
          speed_modifier -= 0.2
        when :critical
          speed_modifier -= 0.3
        end
      end
    end
    if speed_modifier < 0.1
      speed_modifier = 0.1
    end
    return speed_modifier
  end
end