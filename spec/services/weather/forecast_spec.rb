require "rails_helper"

RSpec.describe Weather::Forecast do
  it "normalizes cached into a predicate" do
    forecast = described_class.new(cached: true)

    expect(forecast).to be_cached
  end

  it "normalizes missing extended periods into an empty array" do
    forecast = described_class.new

    expect(forecast.extended_periods).to eq([])
  end
end
