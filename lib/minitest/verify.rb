# frozen_string_literal: true

require_relative "verify/version"

module Minitest
  module Verify
    class VerificationFailedError < StandardError; end

    class VerificationFailure < Minitest::Assertion
      def result_label
        "Verification Failure"
      end
    end

    class VerificationError < Minitest::UnexpectedError
      def result_label
        "Verification Error"
      end
    end

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

      @normal_failures = failures.dup
      failures.clear

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
      yield

      assertions = failures.select { |f| f.class == Minitest::Assertion }
      unexpected_errors = failures.select { |f| f.class == Minitest::UnexpectedError }

      failures.clear
      failures.concat(@normal_failures)

      if unexpected_errors.any?
        unexpected_errors.each do |unexpected_error|
          failures << VerificationError.new(unexpected_error.error)
        end

        raise VerificationFailedError
      end

      if assertions.empty?
        exception = VerificationFailure.new("Expected at least one assertion to fail.")
        exception.set_backtrace(@current_caller)
        failures << exception

        raise VerificationFailedError
      end
    end
  end
end
