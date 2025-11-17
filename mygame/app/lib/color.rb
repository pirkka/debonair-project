module Color

  def self.hsl_to_rgb (hue,saturation,luminence)
    r,g,b = self.hue_to_rgb(hue,saturation,luminence)
    color = {}
    color[:r] = r
    color[:g] = g
    color[:b] = b
    return color
  end

  def self.hue_to_hex (hue,saturation,luminence)
    
    r,g,b = self.hue_to_rgb(hue,saturation,luminence)
    
    rs = float_to_html_hex(r)
    gs = float_to_html_hex(g)
    bs = float_to_html_hex(b)
    
    hex = '#' + rs + gs + bs    
    return hex
  end
    
  def self.hue_to_rgb (hue,saturation,luminence)
    
    # hue on jotain väliltä 1-360
    # saturation jotain väliltä 0-100
    # luminance jotain väliltä 0-100
    
    if saturation > 0 then
      
      nh = hue / 60.0;
      ns = saturation / 100.0
      nl = luminence / 100.0
      
      lh = nh.floor
      nf = nh - (lh * 1.0)
      
      np = nl * (1.0 - ns)
      nq = nl * (1.0 - ns * nf)
      nt = nl * (1.0 - ns * (1.0 - nf))
      
      case lh
      when 1
        r = nq * 255
        g = nl * 255
        b = np * 255
      when 2
        r = np * 255
        g = nl * 255
        b = nt * 255
      when 3
        r = np * 255
        g = nq * 255
        b = nl * 255
      when 4
        r = nt * 255
        g = np * 255
        b = nl * 255
      when 5
        r = nl * 255
        g = np * 255
        b = nq * 255
      else
        r = nl * 255
        g = nt * 255
        b = np * 255
      end
      
      
    else
      
      r = g = b = (luminence * 255) / 100
      
    end
    
    return r, g, b
  end
  
  # Converts a floating point number to a hex number.
  def self.float_to_html_hex (f)
    retval = f.to_i.to_s(base=16)
    if retval.length == 1 then
      retval = '0' + retval
    end
    return retval
  end
  
end