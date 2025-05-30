require "minitest/verify"

module Minitest
  def self.plugin_verify_options(opts, options)
    opts.on "--verify", "Verify tests are not false negatives after running them." do
      options[:verify] = true
    end

    opts.on "--silent", "Ignore verification failures." do
      options[:silent] = true
    end
  end

  def self.plugin_verify_init(options)
    Verify.enabled = options.fetch(:verify, false)
    Verify.silent = options.fetch(:silent, false)
  end
end
