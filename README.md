# Minitest::Verify

Avoid false-positive tests by verifying they fail when key setup is removed.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

## Usage

This is a false-positive test. It always passes because `post` and `comment` are completely unrelated: there's no reason `post.comments` would ever include `comment`.

```rb
require "minitest/autorun"

class PostTest < Minitest::Test
  def test_comments_excludes_hidden_comments
    post = create(:post)
    comment = create(:comment, hidden: true)

    refute_includes post.comments, comment
  end
end
```

We can pull out the key setup and wrap it with `verify_fails_without`:

```rb
require "minitest/autorun"
require "minitest/verify"

class PostTest < Minitest::Test
  include Minitest::Verify

  def test_comments_excludes_hidden_comments
    post = create(:post)
    comment = create(:comment)

    verify_fails_without { comment.update!(hidden: true) }

    refute_includes post.comments, comment
  end
end
```

Now run the test with the `--verify` argument:

```
$ ruby post_test.rb --verify
```

This will cause the test to run twice. First it runs _with_ the contents of the `verify_fails_without` block evaluated (normal run). Then it runs _without_ the contents of the `verify_fails_without` block evaluated (verification run). If the test still passes without having evaluated the code inside the block, it's a false positive and you'll see a verification failure in your test output:

```
# Running:

V

Finished in 0.000380s, 2631.5783 runs/s, 5263.1565 assertions/s.

  1) Verification Failure:
PostTest#test_comments_excludes_hidden_comments [post_test.rb:11]:
Expected at least one assertion to fail.

1 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```
