require "net/http"

module Weather
  # Shared outbound HTTP boundary for weather services.
  # It centralizes request headers and explicit timeouts so API clients do not call Net::HTTP directly.
  class HttpClient
    DEFAULT_TIMEOUT_SECONDS = 5.0
    DEFAULT_USER_AGENT = "rails-weather-app".freeze

    class << self
      def get(uri, headers: {})
        request = Net::HTTP::Get.new(uri, request_headers(headers))

        Net::HTTP.start(
          uri.hostname,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: timeout_from_env("WEATHER_HTTP_OPEN_TIMEOUT_SECONDS"),
          read_timeout: timeout_from_env("WEATHER_HTTP_READ_TIMEOUT_SECONDS"),
          write_timeout: timeout_from_env("WEATHER_HTTP_WRITE_TIMEOUT_SECONDS")
        ) do |http|
          http.request(request)
        end
      end

      private

      def request_headers(headers)
        base_headers.merge(headers)
      end

      def base_headers
        headers = { "User-Agent" => user_agent }
        headers["From"] = contact if contact.present?
        headers
      end

      def user_agent
        ENV.fetch("WEATHER_USER_AGENT") do
          contact.present? ? "#{DEFAULT_USER_AGENT} (#{contact})" : DEFAULT_USER_AGENT
        end
      end

      def contact
        ENV["WEATHER_CONTACT"].presence
      end

      def timeout_from_env(name)
        Float(ENV.fetch(name, DEFAULT_TIMEOUT_SECONDS))
      rescue ArgumentError
        DEFAULT_TIMEOUT_SECONDS
      end
    end
  end
end
