class SoundFX

  @@fx_volume = 0.05

  def self.play_sound(args, kind)
    case kind
    when :walk
      variation = Numeric.rand(1..6)
      args.outputs.audio[:walk] = {
        input: "sounds/walk-#{variation}.mp3",
        gain: @@fx_volume
      }
    when :staircase
      args.outputs.audio[:staircase] = {
        input: "sounds/staircase.mp3",
        gain: @@fx_volume
      }
    when :miss
      args.outputs.audio[:miss] = {
        input: "sounds/miss.mp3",
        gain: @@fx_volume
      }
    when :hit
      args.outputs.audio[:punch] = {
        input: "sounds/punch.mp3",
        gain: @@fx_volume
      }
    else
      puts "Sound #{kind} not found!"
    end
  end
end