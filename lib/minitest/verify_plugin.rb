require "minitest/verify"

module Minitest
  def self.plugin_verify_options(opts, options)
    opts.on "--verify", "Verify tests are not false negatives after running them." do
      options[:enabled] = true
    end
  end

  def self.plugin_verify_init(options)
    Verify.enabled = options.fetch(:enabled, false)
  end
end
