class Run
  attr_accessor :dungeon, :hero  


  def initialize(args)
  end

  def setup args
    Architect.create_seed(args)
    if $fixed_seed
      seed = $fixed_seed
      Architect.set_seed(args, seed) # for testing purposes
    end
    Architect.use_seed(args)
    Architect.instance.setup({})
    Architect.instance.architect_dungeon(args)
    @dungeon = args.state.dungeon # TODO: should we only access these things below the :run attribute?
    @hero = args.state.hero
    args.state.current_level = 0
    args.state.kronos = Kronos.new
  end
    
end