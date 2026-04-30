module Weather
  ResolvedLocation = Struct.new(
    :display_name,
    :zip_code,
    :latitude,
    :longitude,
    :cache_key,
    keyword_init: true
  )
end
