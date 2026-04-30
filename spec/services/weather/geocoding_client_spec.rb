require "rails_helper"

RSpec.describe Weather::GeocodingClient do
  describe "#call" do
    it "returns normalized geocoding data for a location query" do
      response = instance_double(Net::HTTPResponse, code: "200", body: geocoding_response_body)
      http_client = class_double(Net::HTTP, get_response: response)

      geocoding_result = described_class.new(http_client: http_client).call("  Cupertino,   CA  ")

      expect(geocoding_result.display_name).to eq("Cupertino, Santa Clara County, California, United States")
      expect(geocoding_result.zip_code).to eq("95014")
      expect(geocoding_result.latitude).to eq(37.3229)
      expect(geocoding_result.longitude).to eq(-122.0322)
      expect(http_client).to have_received(:get_response) do |uri, headers|
        expect(uri.host).to eq("nominatim.openstreetmap.org")
        expect(Rack::Utils.parse_query(uri.query)).to include(
          "addressdetails" => "1",
          "countrycodes" => "us",
          "format" => "json",
          "limit" => "1",
          "city" => "Cupertino",
          "state" => "CA"
        )
        expect(headers["Accept"]).to eq("application/json")
        expect(headers["User-Agent"]).to include("rails-weather-app")
      end
    end

    it "uses a structured city and state query when there is no comma" do
      response = instance_double(Net::HTTPResponse, code: "200", body: geocoding_response_body)
      http_client = class_double(Net::HTTP, get_response: response)

      described_class.new(http_client: http_client).call("Sanford FL")

      expect(http_client).to have_received(:get_response) do |uri, _headers|
        expect(Rack::Utils.parse_query(uri.query)).to include(
          "city" => "Sanford",
          "state" => "FL"
        )
      end
    end

    it "uses the unstructured query for other location text" do
      response = instance_double(Net::HTTPResponse, code: "200", body: geocoding_response_body)
      http_client = class_double(Net::HTTP, get_response: response)

      described_class.new(http_client: http_client).call("1 Apple Park Way, Cupertino, CA")

      expect(http_client).to have_received(:get_response) do |uri, _headers|
        expect(Rack::Utils.parse_query(uri.query)).to include("q" => "1 Apple Park Way, Cupertino, CA")
      end
    end

    it "falls back to the street address when a no-comma street address with zip is not found" do
      requested_queries = []
      empty_response = instance_double(Net::HTTPResponse, code: "200", body: [].to_json)
      success_response = instance_double(Net::HTTPResponse, code: "200", body: example_street_response_body)
      responses = [ empty_response, success_response ]
      http_client = class_double(Net::HTTP)

      allow(http_client).to receive(:get_response) do |uri, _headers|
        requested_queries << Rack::Utils.parse_query(uri.query)
        responses.shift
      end

      geocoding_result = described_class.new(http_client: http_client).call("123 Main St. Exampleville FL 12345")

      expect(geocoding_result.display_name).to eq(
        "123, Main Street, Exampleville, Florida, 12345, United States"
      )
      expect(requested_queries.first).to include("q" => "123 Main St. Exampleville FL 12345")
      expect(requested_queries.second).to include("q" => "123 Main St.")
    end

    it "falls back to the street address when a no-comma street address with city is not found" do
      requested_queries = []
      empty_response = instance_double(Net::HTTPResponse, code: "200", body: [].to_json)
      success_response = instance_double(Net::HTTPResponse, code: "200", body: example_street_response_body)
      responses = [ empty_response, success_response ]
      http_client = class_double(Net::HTTP)

      allow(http_client).to receive(:get_response) do |uri, _headers|
        requested_queries << Rack::Utils.parse_query(uri.query)
        responses.shift
      end

      geocoding_result = described_class.new(http_client: http_client).call("123 Main St. Exampleville")

      expect(geocoding_result.display_name).to eq(
        "123, Main Street, Exampleville, Florida, 12345, United States"
      )
      expect(requested_queries.first).to include("q" => "123 Main St. Exampleville")
      expect(requested_queries.second).to include("q" => "123 Main St.")
    end

    it "falls back to city and state when the street address fallback is not found" do
      requested_queries = []
      empty_response = instance_double(Net::HTTPResponse, code: "200", body: [].to_json)
      success_response = instance_double(Net::HTTPResponse, code: "200", body: example_city_state_response_body)
      responses = [ empty_response, empty_response, success_response ]
      http_client = class_double(Net::HTTP)

      allow(http_client).to receive(:get_response) do |uri, _headers|
        requested_queries << Rack::Utils.parse_query(uri.query)
        responses.shift
      end

      geocoding_result = described_class.new(http_client: http_client).call("123 Main St. Exampleville FL")

      expect(geocoding_result.display_name).to eq("Exampleville, Example County, Florida, United States")
      expect(requested_queries.first).to include("q" => "123 Main St. Exampleville FL")
      expect(requested_queries.second).to include("q" => "123 Main St.")
      expect(requested_queries.third).to include(
        "city" => "Exampleville",
        "state" => "FL"
      )
    end

    it "raises a location not found error when geocoding returns no matches" do
      response = instance_double(Net::HTTPResponse, code: "200", body: [].to_json)
      http_client = class_double(Net::HTTP, get_response: response)

      expect do
        described_class.new(http_client: http_client).call("Missing Place, ZZ")
      end.to raise_error(Weather::GeocodingClient::LocationNotFound)
    end

    it "raises a location not found error when geocoding does not return coordinates" do
      response = instance_double(
        Net::HTTPResponse,
        code: "200",
        body: [ { "display_name" => "Missing Coordinates" } ].to_json
      )
      http_client = class_double(Net::HTTP, get_response: response)

      expect do
        described_class.new(http_client: http_client).call("Missing Coordinates")
      end.to raise_error(Weather::GeocodingClient::LocationNotFound)
    end

    it "raises a geocoding error when the service response is not successful" do
      response = instance_double(Net::HTTPResponse, code: "503", body: "")
      http_client = class_double(Net::HTTP, get_response: response)

      expect do
        described_class.new(http_client: http_client).call("Cupertino, CA")
      end.to raise_error(Weather::GeocodingClient::Error, "geocoding request failed")
    end

    it "raises a geocoding error when the request cannot be completed" do
      http_client = class_double(Net::HTTP)

      allow(http_client).to receive(:get_response).and_raise(SocketError)

      expect do
        described_class.new(http_client: http_client).call("Cupertino, CA")
      end.to raise_error(Weather::GeocodingClient::Error, "geocoding request failed")
    end

    it "raises a geocoding error when the response cannot be parsed" do
      response = instance_double(Net::HTTPResponse, code: "200", body: "not json")
      http_client = class_double(Net::HTTP, get_response: response)

      expect do
        described_class.new(http_client: http_client).call("Cupertino, CA")
      end.to raise_error(Weather::GeocodingClient::Error, "geocoding response could not be parsed")
    end

    def geocoding_response_body
      [
        {
          "display_name" => "Cupertino, Santa Clara County, California, United States",
          "lat" => "37.3229",
          "lon" => "-122.0322",
          "address" => {
            "postcode" => "95014-2083"
          }
        }
      ].to_json
    end

    def example_city_state_response_body
      [
        {
          "display_name" => "Exampleville, Example County, Florida, United States",
          "lat" => "28.8117345",
          "lon" => "-81.2680223",
          "address" => {
            "city" => "Exampleville",
            "state" => "Florida"
          }
        }
      ].to_json
    end

    def example_street_response_body
      [
        {
          "display_name" =>
            "123, Main Street, Exampleville, Florida, 12345, United States",
          "lat" => "28.8066021",
          "lon" => "-81.3493758",
          "address" => {
            "house_number" => "123",
            "road" => "Main Street",
            "postcode" => "12345"
          }
        }
      ].to_json
    end
  end
end
