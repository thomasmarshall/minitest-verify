# frozen_string_literal: true

require_relative "verify/version"

module Minitest
  module Verify
    class VerificationFailedError < StandardError; end

    class << self
      attr_accessor :enabled
      attr_accessor :silent
    end

    NO_VALUE = Object.new

    def verify_fails_without(correct_value = NO_VALUE, incorrect_value = NO_VALUE, &block)
      if correct_value == NO_VALUE && incorrect_value == NO_VALUE && block.nil?
        raise ArgumentError, "Either a block or a pair of arguments must be provided"
      end

      if block
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
      else
        if @current_caller
          # If @current_caller is set, we are in the verification phase.
          # Return the incorrect value if it's the one currently being verified.
          if caller(1..1).first == @current_caller[0]
            incorrect_value
          else
            correct_value
          end
        else
          # If @current_caller is not set, we're in the normal test phase.
          # Return the correct value.
          callers << caller
          correct_value
        end
      end
    end

    def fail_with(&block)
      if @current_caller
        block.call if caller(1..1).first == @current_caller[0]
      else
        callers << caller
      end
    end

    def fail_without(&block)
      if @current_caller
        block.call unless caller(1..1).first == @current_caller[0]
      else
        callers << caller
        block.call
      end
    end

    alias_method :mutate, :verify_fails_without

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

      # Run the verification logic but don't raise an error if it fails.
      if Verify.silent
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
