require "rails_helper"

RSpec.describe Weather::HttpClient do
  ENV_NAMES = %w[
    WEATHER_CONTACT
    WEATHER_HTTP_OPEN_TIMEOUT_SECONDS
    WEATHER_HTTP_READ_TIMEOUT_SECONDS
    WEATHER_HTTP_WRITE_TIMEOUT_SECONDS
    WEATHER_USER_AGENT
  ].freeze

  around do |example|
    original_env = ENV_NAMES.to_h { |name| [ name, ENV[name] ] }
    ENV_NAMES.each { |name| ENV.delete(name) }

    example.run
  ensure
    original_env.each do |name, value|
      value.nil? ? ENV.delete(name) : ENV[name] = value
    end
  end

  describe ".get" do
    it "sends configured headers and explicit timeouts" do
      ENV["WEATHER_CONTACT"] = "weather@example.com"
      ENV["WEATHER_HTTP_OPEN_TIMEOUT_SECONDS"] = "1.5"
      ENV["WEATHER_HTTP_READ_TIMEOUT_SECONDS"] = "2.5"
      ENV["WEATHER_HTTP_WRITE_TIMEOUT_SECONDS"] = "3.5"
      ENV["WEATHER_USER_AGENT"] = "custom-weather/1.0"

      response = instance_double(Net::HTTPResponse)
      http = instance_double(Net::HTTP, request: response)

      allow(Net::HTTP).to receive(:start).and_yield(http)

      result = described_class.get(
        URI("https://api.weather.gov/points/37.3229,-122.0322"),
        headers: { "Accept" => "application/geo+json" }
      )

      expect(result).to eq(response)
      expect(Net::HTTP).to have_received(:start).with(
        "api.weather.gov",
        443,
        use_ssl: true,
        open_timeout: 1.5,
        read_timeout: 2.5,
        write_timeout: 3.5
      )
      expect(http).to have_received(:request) do |request|
        expect(request).to be_a(Net::HTTP::Get)
        expect(request.path).to eq("/points/37.3229,-122.0322")
        expect(request["Accept"]).to eq("application/geo+json")
        expect(request["From"]).to eq("weather@example.com")
        expect(request["User-Agent"]).to eq("custom-weather/1.0")
      end
    end

    it "uses a default user agent and timeout values" do
      response = instance_double(Net::HTTPResponse)
      http = instance_double(Net::HTTP, request: response)

      allow(Net::HTTP).to receive(:start).and_yield(http)

      described_class.get(URI("http://example.com/search"))

      expect(Net::HTTP).to have_received(:start).with(
        "example.com",
        80,
        use_ssl: false,
        open_timeout: 5.0,
        read_timeout: 5.0,
        write_timeout: 5.0
      )
      expect(http).to have_received(:request) do |request|
        expect(request["From"]).to be_nil
        expect(request["User-Agent"]).to eq("rails-weather-app")
      end
    end

    it "adds contact information to the default user agent" do
      ENV["WEATHER_CONTACT"] = "weather@example.com"

      response = instance_double(Net::HTTPResponse)
      http = instance_double(Net::HTTP, request: response)

      allow(Net::HTTP).to receive(:start).and_yield(http)

      described_class.get(URI("https://api.weather.gov/gridpoints/MTR/85,105/forecast"))

      expect(http).to have_received(:request) do |request|
        expect(request["From"]).to eq("weather@example.com")
        expect(request["User-Agent"]).to eq("rails-weather-app (weather@example.com)")
      end
    end
  end
end
