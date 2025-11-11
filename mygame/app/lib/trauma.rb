class Trauma
  attr_reader :kind, :category
  def initialize(kind, category)
    @kind = kind
    @category = category
    @treatments = []
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

  def self.inflict(entity, kind)
    category = kinds.find { |cat, kinds| kinds.include?(kind) }&.first
    raise 'Unknown trauma kind' unless category
    trauma = Trauma.new(kind, category)
    entity.traumas << trauma
    trauma
  end
end