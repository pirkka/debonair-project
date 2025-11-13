class Trauma
  attr_reader :kind, :category, :treatments, :hit_location, :last_treated, :severity
  def initialize(kind, hit_location, severity)
    @kind = kind
    @category = Trauma.kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    @treatments = []
    @hit_location = hit_location
    @severity = severity
    @last_treated = nil # simulation time when applied
  end

  def self.categories
    [:physical, :mental, :emotional]
  end

  def self.severities
    [:minor, :moderate, :severe, :critical]
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

  def self.inflict(entity, hit_location, kind, severity, args)
    category = kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    raise 'Unknown trauma kind' unless category
    trauma = Trauma.new(kind, hit_location, severity)
    trauma.instance_variable_set(:@hit_location, hit_location)  
    entity.traumas << trauma
    entity.increase_need(:avoid_being_hit)
    printf "Inflicted #{kind} trauma to #{entity.class} at #{hit_location}. Has now #{entity.traumas.size} traumas.\n"
    return trauma
  end

  def self.determine_morbidity(entity)
    printf "Determining morbidity for entity with %d traumas.\n" % [entity.traumas.size]
    death_score = 0
    death_threshold = 10
    entity.traumas.each do |trauma|
      if body_parts_counted_for_death.include?(trauma.hit_location)
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
end