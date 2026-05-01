module Weather
  # Normalized geocoding data returned by the geocoder boundary
  GeocodingResult = Struct.new(
    :display_name,
    :zip_code,
    :latitude,
    :longitude,
    keyword_init: true
  )
end
