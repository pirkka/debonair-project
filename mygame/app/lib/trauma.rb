class Trauma
  attr_reader :kind, :category, :treatments, :hit_location, :last_treated
  def initialize(kind, hit_location)
    @kind = kind
    @category = Trauma.kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    @treatments = []
    @hit_location = hit_location
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

  def self.inflict(entity, hit_location, kind)
    category = kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    raise 'Unknown trauma kind' unless category
    trauma = Trauma.new(kind, category)
    trauma.instance_variable_set(:@hit_location, hit_location)  
    entity.traumas << trauma
    printf "Inflicted #{kind} trauma to #{entity.class} at #{hit_location}. Has now #{entity.traumas.size} traumas.\n"
    return trauma
  end

  def self.determine_morbidity(entity)
    death_score = 0
    death_threshold = 3
    entity.traumas.each do |trauma|
      if body_parts_counted_for_death.include?(trauma.hit_location)
        death_score += 1
      end
    end
    if death_score >= death_threshold
      return true
    end
  end

  def self.body_parts_counted_for_death
    [:head, :torso, :heart, :lungs, :brain, :spine, :abdomen, :forehead, :top_of_skull, :back_of_skull, :colon, :intestines, :stomach, :genitals, :left_temple, :right_temple, :thorax, :eyes, :left_eye, :right_eye]
  end
end