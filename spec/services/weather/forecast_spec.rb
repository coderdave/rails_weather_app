require "rails_helper"

RSpec.describe Weather::Forecast do
  it "normalizes cached into a predicate" do
    forecast = described_class.new(cached: true)

    expect(forecast).to be_cached
  end
end
