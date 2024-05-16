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

      return Result.from(self) unless Verify.enabled && failures.none?

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

      if failures.any? { |f| f.is_a?(Minitest::UnexpectedError) }
        raise VerificationFailedError
      end

      if failures.reject! { |f| f.is_a?(Minitest::Assertion) }
        return
      end

      exception = Minitest::Assertion.new("Expected at least one assertion to fail.")
      exception.set_backtrace(@current_caller)
      failures << exception

      raise VerificationFailedError
    end
  end
end
