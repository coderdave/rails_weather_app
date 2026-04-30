module Weather
  class LocationQuery
    ZIP_CODE_PATTERN = /(?<!\d)(\d{5})(?:-\d{4})?(?!\d)/
    ZIP_CODE_ONLY_PATTERN = /\A\d{5}(?:-\d{4})?\z/
    CITY_STATE_WITHOUT_COMMA_PATTERN = /\A[A-Za-z][A-Za-z .'-]*\s+[A-Za-z]{2}(?:\s+\d{5}(?:-\d{4})?)?\z/
    STREET_ADDRESS_WITHOUT_COMMA_PATTERN = /\A\d+\s+.+\s+[A-Za-z]{2}(?:\s+\d{5}(?:-\d{4})?)?\z/

    attr_reader :normalized_query

    def initialize(raw_query)
      @normalized_query = normalize(raw_query)
    end

    def zip_code?
      normalized_query.match?(ZIP_CODE_ONLY_PATTERN)
    end

    def city_state?
      return false if zip_code?

      comma_separated_city_state? || no_comma_city_state?
    end

    def street_address?
      return false if zip_code?

      comma_separated_street_address? || no_comma_street_address?
    end

    def recognized?
      zip_code? || city_state? || street_address?
    end

    def zip_code
      normalized_query.match(ZIP_CODE_PATTERN)&.[](1)
    end

    def to_s
      normalized_query
    end

    private

    def normalize(raw_query)
      raw_query.to_s.strip.gsub(/\s+/, " ")
    end

    def components
      @components ||= normalized_query.split(",").map(&:strip).reject(&:empty?)
    end

    def comma_separated_city_state?
      components.length == 2 && state_component?(components.last)
    end

    def comma_separated_street_address?
      # street addresses should include at least street, city, and state components
      components.length >= 3 && state_component?(components.last)
    end

    def no_comma_city_state?
      !contains_comma? && normalized_query.match?(CITY_STATE_WITHOUT_COMMA_PATTERN)
    end

    def no_comma_street_address?
      !contains_comma? && normalized_query.match?(STREET_ADDRESS_WITHOUT_COMMA_PATTERN)
    end

    def contains_comma?
      normalized_query.include?(",")
    end

    def state_component?(value)
      state = value.to_s.sub(ZIP_CODE_PATTERN, "").strip

      state.match?(/\A[A-Za-z]{2}\z/) || state.match?(/\A[A-Za-z][A-Za-z .'-]+\z/)
    end
  end
end
