module Weather
  # Display name and coordinates for a resolved user location
  ResolvedLocation = Struct.new(
    :display_name,
    :latitude,
    :longitude,
    keyword_init: true
  )
end
