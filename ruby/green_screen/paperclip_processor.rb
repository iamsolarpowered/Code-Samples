module Paperclip
  class SwapBack < Thumbnail
    
    def transformation_command
      [resize, rotate, green_clean, swap_background, apply_overlay, super].compact.join(' ')
    end
    
    private
    
    def green_clean
      "-alpha on -channel alpha -fx 'abs(u.hue - p{#{image_profile.sample_coords}}.hue) > #{image_profile.hue_threshold} || u.saturation < #{image_profile.saturation_threshold} || u.intensity < #{image_profile.black_threshold} || u.intensity > #{image_profile.white_threshold}' -blur #{image_profile.alpha_blur} -level #{image_profile.alpha_level}" unless image_profile.skip_background_removal
    end
    
    def resize
      "-resize '#{image_profile.resize}'"
    end
    
    def rotate
      "-rotate #{image_profile.rotate}"
    end
    
    def swap_background
      "#{background_path} +swap -gravity South -geometry #{position} -composite" if background_path #rescue nil
    end
    
    def apply_overlay
      "#{overlay_path} -composite" if overlay_path
    end
    
    def target
      @attachment.instance
    end
    
    def image_profile
      target.image_profile if target
    end
    
    def position
      target.background.position || '0-0'
    end
    
    def background_path
      p = target.background.photo.path(:large) rescue nil
      p && File.exist?(p) ? p : false
    end
    
    def overlay_path
      p = target.background.overlay.path(:original) rescue nil
      p && File.exist?(p) ? p : false
    end
  end
end
