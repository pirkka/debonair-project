class SeededRandom
  def initialize(seed)
    @seed = seed.to_i
  end
  
  def nxt
    # Linear Congruential Generator (LCG)
    @seed = (@seed * 1664525 + 1013904223) % 4294967296
    @seed / 4294967296.0
  end

  def d6
    nxt_int(1, 6)
  end

  def d8
    nxt_int(1, 8)
  end

  def d10
    nxt_int(1, 10)
  end 

  def d12
    nxt_int(1, 12)
  end

  def d20
    nxt_int(1, 20)
  end

  def nxt_bool
    nxt < 0.5
  end

  def nxt_int(min, max)
    (nxt * (max - min + 1)).floor + min
  end
  
  def nxt_float(min = 0.0, max = 1.0)
    min + (nxt * (max - min))
  end
  
  def choice(array)
    array[next_int(0, array.length - 1)]
  end
  
  def shuffle(array)
    result = array.dup
    (result.length - 1).downto(1) do |i|
      j = next_int(0, i)
      result[i], result[j] = result[j], result[i]
    end
    result
  end
end