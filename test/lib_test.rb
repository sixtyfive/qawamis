require 'test_helper'

class LibTest < ActiveSupport::TestCase
  def test_string_number_returns_true_if_string_is_number
    assert_equal "5".number?, true
  end

  def test_string_number_returns_false_if_string_no_number
    assert_equal "abc3def".number?, false
  end
end
