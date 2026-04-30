module Weather
  class LocationQuery
    MINIMUM_LENGTH = 3
    MAXIMUM_LENGTH = 255
    UNSUPPORTED_CHARACTER_PATTERN = /[<>{}\[\]|\\]/
    ZIP_CODE_PATTERN = /(?<!\d)(\d{5})(?:-\d{4})?(?!\d)/

    attr_reader :normalized_query

    def initialize(raw_query)
      @normalized_query = normalize(raw_query)
    end

    def validation_error
      return "Enter a location" if normalized_query.blank?
      return "Location is too long" if normalized_query.length > MAXIMUM_LENGTH
      return "Enter a more specific location" if normalized_query.length < MINIMUM_LENGTH

      "Location contains unsupported characters" if normalized_query.match?(UNSUPPORTED_CHARACTER_PATTERN)
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
  end
end
