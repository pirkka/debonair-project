class SoundFX

  @@fx_volume = 0.1

  def self.play(kind, args)
    self.play_sound(kind, args)
  end
  def self.play_sound(kind, args, volume = 1.0)
    if args.outputs.audio[kind]
      # sound is already playing, do not overlap
      return
    end
    printf "Playing sound: %s\n" % [kind.to_s]
    args.outputs.audio[kind] = {
        input: "sounds/#{kind}.mp3",
        gain: @@fx_volume * volume
    }
  end
  print "SoundFX was played.\n"
end