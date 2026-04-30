require "rails_helper"

RSpec.describe Weather::LocationQuery do
  it "normalizes whitespace in the submitted location" do
    query = described_class.new("  Cupertino,   CA  ")

    expect(query.to_s).to eq("Cupertino, CA")
  end

  it "returns an error for a blank location" do
    query = described_class.new("   ")

    expect(query.validation_error).to eq("Enter a location")
  end

  it "returns an error for a location that is too long" do
    query = described_class.new("a" * 256)

    expect(query.validation_error).to eq("Location is too long")
  end

  it "returns an error for a location that is too short" do
    query = described_class.new("NY")

    expect(query.validation_error).to eq("Enter a more specific location")
  end

  it "returns an error for unsupported characters" do
    query = described_class.new("Cupertino | CA")

    expect(query.validation_error).to eq("Location contains unsupported characters")
  end

  it "allows geocodable location text without requiring a city/state shape" do
    query = described_class.new("Cupertino")

    expect(query.validation_error).to be_nil
  end

  it "extracts a zip code search" do
    query = described_class.new("95014")

    expect(query.validation_error).to be_nil
    expect(query.zip_code).to eq("95014")
  end

  it "allows a city and state search" do
    query = described_class.new("Cupertino, CA")

    expect(query.validation_error).to be_nil
    expect(query.zip_code).to be_nil
  end

  it "extracts a zip code from a city and state search" do
    query = described_class.new("Cupertino, CA 95014")

    expect(query.validation_error).to be_nil
    expect(query.zip_code).to eq("95014")
  end

  it "allows a city and state search without a comma" do
    query = described_class.new("Sanford FL")

    expect(query.validation_error).to be_nil
    expect(query.zip_code).to be_nil
  end

  it "allows a street address with city and state" do
    query = described_class.new("1 Apple Park Way, Cupertino, CA")

    expect(query.validation_error).to be_nil
    expect(query.zip_code).to be_nil
  end

  it "extracts a zip code from a street address" do
    query = described_class.new("1 Apple Park Way, Cupertino, CA 95014")

    expect(query.validation_error).to be_nil
    expect(query.zip_code).to eq("95014")
  end

  it "extracts a zip code from a street address without commas" do
    query = described_class.new("6068 Saint Julian Dr. Sanford FL 32771")

    expect(query.zip_code).to eq("32771")
  end
end
