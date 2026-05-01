require "json"
require "uri"

module Weather
  # Resolves latitude and longitude into the NWS forecast endpoint URLs for that grid point
  class NwsPointsClient
    ENDPOINT = "https://api.weather.gov/points".freeze
    REQUEST_HEADERS = {
      "Accept" => "application/geo+json"
    }.freeze

    class Error < StandardError; end

    def self.call(resolved_location)
      new.call(resolved_location)
    end

    def initialize(http_client: HttpClient)
      @http_client = http_client
    end

    def call(resolved_location)
      response = fetch_response(points_uri(resolved_location))

      raise Error, "nws points request failed" unless response.code.to_i == 200

      build_result(response.body)
    end

    private

    attr_reader :http_client

    def fetch_response(uri)
      http_client.get(uri, headers: REQUEST_HEADERS)
    rescue StandardError
      raise Error, "nws points request failed"
    end

    def points_uri(resolved_location)
      URI("#{ENDPOINT}/#{coordinate_for(resolved_location.latitude)},#{coordinate_for(resolved_location.longitude)}")
    rescue ArgumentError, TypeError
      raise Error, "nws points coordinates are invalid"
    end

    def coordinate_for(value)
      # nws redirects high precision coordinates, so round before the request
      format("%.4f", Float(value))
    end

    def build_result(response_body)
      properties = JSON.parse(response_body).fetch("properties")
      relative_location = properties.fetch("relativeLocation").fetch("properties")

      NwsPointsResult.new(
        forecast_url: properties.fetch("forecast"),
        forecast_hourly_url: properties.fetch("forecastHourly"),
        city: relative_location.fetch("city"),
        state: relative_location.fetch("state"),
        time_zone: properties.fetch("timeZone")
      )
    rescue JSON::ParserError, KeyError
      raise Error, "nws points response could not be parsed"
    end
  end
end
