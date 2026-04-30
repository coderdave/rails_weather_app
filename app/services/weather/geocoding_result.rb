module Weather
  GeocodingResult = Struct.new(
    :display_name,
    :zip_code,
    :latitude,
    :longitude,
    keyword_init: true
  )
end
