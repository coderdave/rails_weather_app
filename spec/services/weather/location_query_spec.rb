require "rails_helper"

RSpec.describe Weather::LocationQuery do
  it "normalizes whitespace in the submitted location" do
    query = described_class.new("  Cupertino,   CA  ")

    expect(query.to_s).to eq("Cupertino, CA")
  end

  it "recognizes a zip code search" do
    query = described_class.new("95014")

    expect(query).to be_zip_code
    expect(query).to be_recognized
    expect(query.zip_code).to eq("95014")
  end

  it "recognizes a city and state search" do
    query = described_class.new("Cupertino, CA")

    expect(query).to be_city_state
    expect(query).to be_recognized
    expect(query.zip_code).to be_nil
  end

  it "recognizes a city and state search with a zip code" do
    query = described_class.new("Cupertino, CA 95014")

    expect(query).to be_city_state
    expect(query).to be_recognized
    expect(query.zip_code).to eq("95014")
  end

  it "recognizes a street address with city and state" do
    query = described_class.new("1 Apple Park Way, Cupertino, CA")

    expect(query).to be_street_address
    expect(query).to be_recognized
    expect(query.zip_code).to be_nil
  end

  it "recognizes a street address with city, state, and zip code" do
    query = described_class.new("1 Apple Park Way, Cupertino, CA 95014")

    expect(query).to be_street_address
    expect(query).to be_recognized
    expect(query.zip_code).to eq("95014")
  end

  it "does not recognize incomplete location text" do
    query = described_class.new("Cupertino")

    expect(query).not_to be_recognized
  end
end
