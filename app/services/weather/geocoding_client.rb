require "json"
require "net/http"

module Weather
  class GeocodingClient
    # nws requires coordinates, and nominatim gives us a no-key geocoder for zip, city, and address searches
    ENDPOINT = URI("https://nominatim.openstreetmap.org/search").freeze
    # nominatim asks clients to identify themselves instead of using a generic ruby user agent
    REQUEST_HEADERS = {
      "Accept" => "application/json",
      "User-Agent" => "rails-weather-app coding-assessment"
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

    def initialize(http_client: Net::HTTP)
      @http_client = http_client
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)

      search_uris(location_query).each do |uri|
        response = fetch_response(uri)

        raise Error, "geocoding request failed" unless response.code.to_i == 200

        return build_result(response.body)
      rescue LocationNotFound
        next
      end

      raise LocationNotFound, "location was not found"
    end

    private

    attr_reader :http_client

    def fetch_response(uri)
      http_client.get_response(uri, REQUEST_HEADERS)
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
      tokens.rindex { |token| STREET_SUFFIXES.include?(token.downcase.delete(".")) }
    end

    def postal_code_params(location_query)
      return unless location_query.zip_code

      { postalcode: location_query.zip_code }
    end

    def build_result(response_body)
      results = JSON.parse(response_body)
      raise Error, "geocoding response could not be parsed" unless results.is_a?(Array)

      result = results.first
      raise LocationNotFound, "location was not found" unless result
      raise Error, "geocoding response could not be parsed" unless result.is_a?(Hash)

      GeocodingResult.new(
        display_name: result.fetch("display_name"),
        zip_code: zip_code_from(result),
        latitude: latitude_from(result),
        longitude: longitude_from(result)
      )
    rescue JSON::ParserError, KeyError, ArgumentError
      raise Error, "geocoding response could not be parsed"
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
