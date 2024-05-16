require "minitest/autorun"
require "minitest/verify"

module Minitest
  class VerifyTest < Minitest::Test
    def test_passing_test
      test_class = build_test_class do
        def test_foo
          a = 1
          verify_fails_without { a += 1 }
          assert_equal 2, a
        end
      end

      result = test_class.new(:test_foo).run

      assert_equal 1, result.assertions
      assert_empty result.failures
    end

    def test_failing_test
      test_class = build_test_class do
        def test_foo
          a = 1
          verify_fails_without { a *= 1 }
          assert_equal 2, a
        end
      end

      result = test_class.new(:test_foo).run

      assert_equal 1, result.assertions
      assert_equal 1, result.failures.size
      assert_match "Expected: 2\n  Actual: 1", result.failures.first.message
    end

    def test_verifying_unnecessary_setup
      test_class = build_test_class do
        def test_foo
          a = 1
          verify_fails_without { nil }
          assert_equal 1, a
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 2, result.assertions
      assert_equal 1, result.failures.size
      assert_match "Expected at least one assertion to fail.", result.failures.first.message
    end

    def test_verifying_necessary_setup
      test_class = build_test_class do
        def test_foo
          a = 1
          verify_fails_without { a += 1 }
          assert_equal 2, a
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 2, result.assertions
      assert_empty result.failures
    end

    def test_verifying_failing_test
      test_class = build_test_class do
        def test_foo
          a = 1
          verify_fails_without { nil }
          assert_equal 2, a
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 2, result.assertions
      assert_equal 1, result.failures.size
      assert_match "Expected: 2\n  Actual: 1", result.failures.first.message
    end

    def test_multiple_assertions
      test_class = build_test_class do
        def test_foo
          a = 1
          verify_fails_without { a += 1 }
          verify_fails_without { nil }
          verify_fails_without { a += 1 }
          assert_equal 3, a
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 3, result.assertions
      assert_equal 1, result.failures.size
      assert_match "Expected at least one assertion to fail.", result.failures.first.message
    end

    def test_unexpected_error
      test_class = build_test_class do
        def test_foo
          a = verify_fails_without { 1 }
          a *= 3
          assert_equal 3, a
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 1, result.assertions
      assert_equal 1, result.failures.size
      assert_match "NoMethodError: undefined method `*' for nil", result.failures.first.message
    end

    def test_setup_method
      test_class = build_test_class do
        def setup
          @a = 1
          verify_fails_without { @a += 1 }
        end

        def test_foo
          assert_equal 2, @a
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 2, result.assertions
      assert_empty result.failures
    end

    def test_failing_test_without_verification
      test_class = build_test_class do
        def test_foo
          assert_equal "abc", "def"
        end
      end

      result = enabled { test_class.new(:test_foo).run }

      assert_equal 1, result.assertions
      assert_equal 1, result.failures.size
      assert_match "Expected: \"abc\"\n  Actual: \"def\"", result.failures.first.message
    end

    private

    def enabled
      Minitest::Verify.enabled = true
      yield
    ensure
      Minitest::Verify.enabled = false
    end

    def build_test_class(&block)
      test_class = Class.new(Minitest::Test)
      test_class.include(Minitest::Verify)
      test_class.class_eval(&block)
      test_class
    end
  end
end
