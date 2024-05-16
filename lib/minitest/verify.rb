# frozen_string_literal: true

require_relative "verify/version"

module Minitest
  module Verify
    class VerificationFailedError < StandardError; end

    class << self
      attr_accessor :enabled
    end

    def verify_fails_without(&block)
      if @current_caller
        block.call unless caller[0] == @current_caller[0]
      else
        callers << caller
        block.call
      end
    end

    def run
      super

      return Result.from(self) unless Verify.enabled

      begin
        while @current_caller = callers.shift
          with_verification { super }
        end
      rescue VerificationFailedError
        callers.clear
      end

      Result.from(self)
    end

    private

    def callers
      @callers ||= []
    end

    def with_verification
      existing_failures = failures.dup
      failures.clear

      yield

      assertions = failures.select { |f| f.class == Minitest::Assertion }
      unexpected_errors = failures.select { |f| f.class == Minitest::UnexpectedError }

      failures.clear
      failures.concat(existing_failures)

      if unexpected_errors.any?
        failures.concat(unexpected_errors)

        raise VerificationFailedError
      end

      if assertions.empty?
        exception = Minitest::Assertion.new("Expected at least one assertion to fail.")
        exception.set_backtrace(@current_caller)
        failures << exception

        raise VerificationFailedError
      end
    end
  end
end
