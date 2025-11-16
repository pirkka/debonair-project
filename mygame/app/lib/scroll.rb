class Scroll < Item
  def initialize
    @title = "scroll of mapping"
    @description = "A magical scroll that glows with arcane energy."
    super(:scroll_of_mapping, :scroll)
  end

  def use(user, args)
    if user != args.state.hero
      return
    end
    case @kind
    when :scroll_of_mapping
      HUD.output_message args, "You read the scroll. You gain knowledge of the level layout!"
      Tile.auto_map_whole_level args    
    else
      printf "Unknown scroll kind: %s\n" % [@kind.to_s]
    end
    args.state.hero.carried_items.delete(self)
    args.state.kronos.spend_time(args.state.hero, args.state.hero.mental_speed, args)
  end
end