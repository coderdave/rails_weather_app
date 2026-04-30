require "json"
require "net/http"

module Weather
  class GeocodingClient
    # nominatim resolves addresses and city/state searches without requiring an api key for this assessment
    ENDPOINT = URI("https://nominatim.openstreetmap.org/search").freeze
    # nominatim asks clients to identify themselves instead of using a generic ruby user agent
    REQUEST_HEADERS = {
      "Accept" => "application/json",
      "User-Agent" => "rails-weather-app coding-assessment"
    }.freeze

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
      response = http_client.get_response(search_uri(location_query), REQUEST_HEADERS)

      raise Error, "geocoding request failed" unless response.code.to_i == 200

      build_result(response.body)
    end

    private

    attr_reader :http_client

    def search_uri(location_query)
      query_params = {
        addressdetails: 1,
        countrycodes: "us",
        format: "json",
        limit: 1,
        q: location_query.to_s
      }

      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(query_params)
      uri
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
        # nominatim returns coordinates as strings, so convert them once at the boundary
        latitude: Float(result.fetch("lat")),
        longitude: Float(result.fetch("lon"))
      )
    rescue JSON::ParserError, KeyError, ArgumentError
      raise Error, "geocoding response could not be parsed"
    end

    def zip_code_from(result)
      result.dig("address", "postcode").to_s.match(LocationQuery::ZIP_CODE_PATTERN)&.[](1)
    end
  end
end
