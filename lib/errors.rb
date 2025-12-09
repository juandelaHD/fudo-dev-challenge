module Errors
  class NotFound < StandardError; end
  class Unauthorized < StandardError; end
  class Conflict < StandardError; end
  class ValidationError < StandardError
    attr_reader :errors
    def initialize(message = 'Validation failed', errors = nil)
      super(message)
      @errors = errors
    end
  end
end
