require "json"
require "uri"

module Weather
  # Wraps Nominatim search requests and translates the first usable result into app geocoding data.
  # Query fallbacks handle common address, city/state, and ZIP-code searches without exposing API details.
  class GeocodingClient
    # nws requires coordinates, and nominatim gives us a no-key geocoder for zip, city, and address searches
    ENDPOINT = URI("https://nominatim.openstreetmap.org/search").freeze
    REQUEST_HEADERS = {
      "Accept" => "application/json"
    }.freeze
    STREET_SUFFIXES = %w[
      aly alley ave avenue blvd boulevard cir circle ct court dr drive hwy highway ln lane pkwy parkway pl place rd road
      st street ter terrace trl trail way
    ].freeze
    CITY_STATE_QUERY_PATTERN =
      /\A(?<city>[A-Za-z][A-Za-z .'-]*?)(?:,\s*|\s+)(?<state>[A-Za-z]{2})\z/

    class Error < StandardError; end
    class LocationNotFound < Error; end

    def self.call(location_query)
      new.call(location_query)
    end

    def initialize(http_client: HttpClient)
      @http_client = http_client
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)

      search_uris(location_query).each do |uri|
        response = fetch_response(uri)

        raise Error, "geocoding request failed" unless response.code.to_i == 200

        return build_result(response.body, location_query)
      rescue LocationNotFound
        next
      end

      raise LocationNotFound, "location was not found"
    end

    private

    attr_reader :http_client

    def fetch_response(uri)
      http_client.get(uri, headers: REQUEST_HEADERS)
    rescue StandardError
      raise Error, "geocoding request failed"
    end

    def search_uris(location_query)
      location_query_params(location_query).map do |query_params|
        search_uri(query_params)
      end
    end

    def search_uri(query_params)
      full_query_params = base_query_params.merge(query_params)

      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(full_query_params)
      uri
    end

    def base_query_params
      {
        addressdetails: 1,
        countrycodes: "us",
        format: "json",
        limit: 1
      }
    end

    def location_query_params(location_query)
      [
        primary_location_query_params(location_query),
        street_address_params(location_query),
        address_city_state_params(location_query),
        postal_code_params(location_query)
      ].compact.uniq
    end

    def primary_location_query_params(location_query)
      city_state_params(location_query) || { q: location_query.to_s }
    end

    def city_state_params(location_query)
      match = location_query.to_s.match(CITY_STATE_QUERY_PATTERN)
      return unless match

      # structured city/state searches prevent abbreviations like FL from being treated as fuzzy text
      { city: match[:city], state: match[:state] }
    end

    def street_address_params(location_query)
      tokens = address_tokens(location_query)
      street_suffix_index = street_suffix_index_for(tokens)
      return unless street_suffix_index
      return if tokens.length == street_suffix_index + 1

      # if a street+city search is not found exactly, retry the street address by itself
      { q: tokens[0..street_suffix_index].join(" ") }
    end

    def address_city_state_params(location_query)
      tokens = address_tokens(location_query)
      state = tokens.pop
      return unless state.to_s.match?(/\A[A-Za-z]{2}\z/)

      street_suffix_index = street_suffix_index_for(tokens)
      return unless street_suffix_index

      city_tokens = tokens[(street_suffix_index + 1)..]
      return if city_tokens.blank?

      # if a street address is not found exactly, fall back to the city/state so a forecast can still be shown
      { city: city_tokens.join(" "), state: state }
    end

    def address_tokens(location_query)
      tokens = location_query.to_s.split
      tokens.pop if tokens.last.to_s.match?(/\A\d{5}(?:-\d{4})?\z/)

      tokens
    end

    def street_suffix_index_for(tokens)
      tokens.rindex { |token| STREET_SUFFIXES.include?(token.downcase.delete(".,")) }
    end

    def postal_code_params(location_query)
      return unless location_query.zip_code

      { postalcode: location_query.zip_code }
    end

    def build_result(response_body, location_query)
      results = JSON.parse(response_body)
      raise Error, "geocoding response could not be parsed" unless results.is_a?(Array)

      result = results.first
      raise LocationNotFound, "location was not found" unless result
      raise Error, "geocoding response could not be parsed" unless result.is_a?(Hash)

      GeocodingResult.new(
        display_name: display_name_from(result, location_query),
        zip_code: zip_code_from(result),
        latitude: latitude_from(result),
        longitude: longitude_from(result)
      )
    rescue JSON::ParserError, KeyError, ArgumentError
      raise Error, "geocoding response could not be parsed"
    end

    def display_name_from(result, location_query)
      address = result.fetch("address", {})
      zip_code = zip_code_from(result)

      if street_address_query?(location_query)
        display_name_from_address(address, zip_code) ||
          display_name_from_query(location_query, address, zip_code) ||
          display_name_from_state_and_zip(address, zip_code) ||
          result.fetch("display_name")
      else
        display_name_from_query(location_query, address, zip_code) ||
          display_name_from_address(address, zip_code) ||
          display_name_from_state_and_zip(address, zip_code) ||
          result.fetch("display_name")
      end
    end

    def display_name_from_address(address, zip_code)
      state = address["state"]
      locality = locality_from(address)
      street_address = street_address_from(address)

      if street_address && locality && state
        display_name_with_zip([ street_address, locality, state ], zip_code)
      elsif locality && state
        display_name_with_zip([ locality, state ], zip_code)
      end
    end

    def display_name_from_query(location_query, address, zip_code)
      state = address["state"]
      locality = query_locality_from(location_query)
      return unless locality && state

      display_name_with_zip([ locality, state ], zip_code)
    end

    def display_name_from_state_and_zip(address, zip_code)
      return unless address["state"] && zip_code

      "#{zip_code}, #{address['state']}"
    end

    def locality_from(address)
      address.values_at("city", "town", "village", "hamlet", "municipality", "suburb", "residential").find do |locality|
        locality.present? && !locality.to_s.match?(LocationQuery::ZIP_CODE_PATTERN)
      end
    end

    def street_address_from(address)
      return unless address["house_number"].present? && address["road"].present?

      "#{address['house_number']} #{address['road']}"
    end

    def display_name_with_zip(parts, zip_code)
      display_name = parts.compact.join(", ")
      return display_name unless zip_code
      return display_name if display_name.start_with?("#{zip_code},") || display_name.end_with?(" #{zip_code}")

      "#{display_name} #{zip_code}"
    end

    def query_locality_from(location_query)
      query = location_query.to_s.sub(/\s+\d{5}(?:-\d{4})?\z/, "")

      city_state_match = query.match(CITY_STATE_QUERY_PATTERN)
      return city_state_match[:city] if city_state_match

      street_address_locality = street_address_locality_from(query)
      return street_address_locality if street_address_locality

      tokens = query.split
      locality = tokens.join(" ").sub(/\b[A-Za-z]{2}\z/, "").delete_suffix(",").strip
      locality if locality.present?
    end

    def street_address_query?(location_query)
      street_suffix_index_for(address_tokens(location_query)).present?
    end

    def street_address_locality_from(query)
      tokens = query.split
      state = tokens.pop.to_s.delete(",")
      return unless state.match?(/\A[A-Za-z]{2}\z/)

      street_suffix_index = street_suffix_index_for(tokens)
      return unless street_suffix_index

      city_tokens = tokens[(street_suffix_index + 1)..]
      return if city_tokens.blank?

      city_tokens.join(" ").delete_suffix(",").strip.presence
    end

    def latitude_from(result)
      # nominatim returns coordinates as strings, so convert them once at the boundary
      Float(result.fetch("lat"))
    rescue KeyError, ArgumentError, TypeError
      raise LocationNotFound, "location coordinates were not found"
    end

    def longitude_from(result)
      # nominatim returns coordinates as strings, so convert them once at the boundary
      Float(result.fetch("lon"))
    rescue KeyError, ArgumentError, TypeError
      raise LocationNotFound, "location coordinates were not found"
    end

    def zip_code_from(result)
      result.dig("address", "postcode").to_s.match(LocationQuery::ZIP_CODE_PATTERN)&.[](1)
    end
  end
end
