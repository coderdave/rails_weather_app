require "json"
require "net/http"

module Weather
  class NwsPointsClient
    ENDPOINT = "https://api.weather.gov/points".freeze
    # nws requires a user agent so they can identify application traffic
    REQUEST_HEADERS = {
      "Accept" => "application/geo+json",
      "User-Agent" => "rails-weather-app coding-assessment"
    }.freeze

    class Error < StandardError; end

    def self.call(resolved_location)
      new.call(resolved_location)
    end

    def initialize(http_client: Net::HTTP)
      @http_client = http_client
    end

    def call(resolved_location)
      response = http_client.get_response(points_uri(resolved_location), REQUEST_HEADERS)

      raise Error, "nws points request failed" unless response.code.to_i == 200

      build_result(response.body)
    end

    private

    attr_reader :http_client

    def points_uri(resolved_location)
      URI("#{ENDPOINT}/#{resolved_location.latitude},#{resolved_location.longitude}")
    end

    def build_result(response_body)
      properties = JSON.parse(response_body).fetch("properties")
      relative_location = properties.fetch("relativeLocation").fetch("properties")

      NwsPointsResult.new(
        forecast_url: properties.fetch("forecast"),
        city: relative_location.fetch("city"),
        state: relative_location.fetch("state"),
        time_zone: properties.fetch("timeZone")
      )
    rescue JSON::ParserError, KeyError
      raise Error, "nws points response could not be parsed"
    end
  end
end
