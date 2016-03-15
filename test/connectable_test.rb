require 'minitest_helper'

class ConnectableTest < Minitest::Test
  def test_can_add_connections
    assert_equal 2, User._connections.count
    
    User.add_connection TertiaryConnection

    assert_equal 3, User._connections.count
  end

  def test_request_fires_connections
    result = User.find(6)
    assert result
    assert_equal Multiconnect::Connection::Result, result.class
  end

  def test_request_returns_first_successful_call
    result = User.find(6)
    assert result.using_fallback?(PrimaryConnection)
  end

  def test_request_continues_on_error
    result = User.explode(id: 6)
    refute_nil $errors
    assert result.using_fallback?(SecondaryConnection)
  end

  def test_failed_connections_raise
    assert_raises Exception do
      SadClass.explode(nil)
    end
  end
end