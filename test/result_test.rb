require 'minitest_helper'

class ResultTest < Minitest::Test
  def test_can_create_with_deafults
    assert Multiconnect::Connection::Result.new
  end

  def test_result_responds_to_success?
    assert Multiconnect::Connection::Result.new(status: :success).success?
    refute Multiconnect::Connection::Result.new.success?
  end

  def test_result_responds_to_using_fallback?
    result = Multiconnect::Connection::Result.new(connection: PrimaryConnection)
    assert result.using_fallback?(PrimaryConnection)
    refute result.using_fallback?(SecondaryConnection)
  end

  def test_result_delegates_method_missing_to_the_data
    assert_equal 2, Multiconnect::Connection::Result.new(data: [1, 2, 3])[1]
  end
end