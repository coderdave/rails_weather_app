module Weather
  ResolvedLocation = Struct.new(
    :display_name,
    :latitude,
    :longitude,
    keyword_init: true
  )
end
