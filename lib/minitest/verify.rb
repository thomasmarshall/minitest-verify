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
        # If @current_caller is set, we are in the verification phase.
        # Evaluate the block unless it is the one currently being verified.
        block.call unless caller(1..1).first == @current_caller[0]
      else
        # If @current_caller is not set, we're in the normal test phase.
        # Collect the caller (there might be multiple per test) and evaluate the block.
        callers << caller
        block.call
      end
    end

    def run
      # If verification is disabled, run the test normally.
      return super unless Verify.enabled

      super

      # If there are normal failures, don't run verification.
      return Result.from(self) if failures.any?

      begin
        # For each caller, run the test again and verify that it fails.
        while (@current_caller = callers.shift)
          with_verification { super }
        end
      rescue VerificationFailedError
        # If verification fails, break out of the loop.
      end

      Result.from(self)
    end

    private

    def callers
      @callers ||= []
    end

    def with_verification
      yield

      # Fail verification if there is an unexpected error.
      # Encountering an unexpected error doesn't imply the test is not a false negative, it might just be broken.
      if failures.any? { |f| f.is_a?(Minitest::UnexpectedError) }
        raise VerificationFailedError
      end

      # Remove all assertion failures so the failing test passes.
      # If at least one was removed, the test is not a false negative.
      if failures.reject! { |f| f.is_a?(Minitest::Assertion) }
        return
      end

      # If there were no assertion failures, we probably have a false negative.
      exception = Minitest::Assertion.new("Expected at least one assertion to fail.")
      exception.set_backtrace(@current_caller)
      failures << exception

      raise VerificationFailedError
    end
  end
end
