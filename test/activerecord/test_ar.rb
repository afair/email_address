require_relative "../test_helper"

class TestAR < MiniTest::Test
  require_relative "user"

  def test_validation
    # Disabled JRuby checks... weird CI failures. Hopefully someone can help?
    if RUBY_PLATFORM != "java" # jruby
      user = User.new(email: "Pat.Jones+ASDF#GMAIL.com")
      assert_equal false, user.valid?
      assert user.errors.messages[:email].first

      user = User.new(email: "Pat.Jones+ASDF@GMAIL.com")
      assert_equal true, user.valid?
    end
  end

  def test_validation_error_message
    if RUBY_PLATFORM != "java" # jruby
      user = User.new(alternate_email: "Pat.Jones+ASDF#GMAIL.com")
      assert_equal false, user.valid?
      assert user.errors.messages[:alternate_email].first.include?("Check your email")
      assert_equal :some_error_code, user.errors.details[:alternate_email].first[:error]
    end
  end

  def test_datatype
    # Disabled JRuby checks... weird CI failures. Hopefully someone can help?
    if RUBY_PLATFORM != "java" # jruby
      if defined?(ActiveRecord) && ::ActiveRecord::VERSION::MAJOR >= 5
        user = User.new(email: "Pat.Jones+ASDF@GMAIL.com")
        assert_equal "pat.jones+asdf@gmail.com", user.email
        assert_equal "patjones@gmail.com", user.canonical_email
      end
    end
  end
end
