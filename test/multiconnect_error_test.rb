require 'minitest_helper'

class MulticonnectErrorTest < Minitest::Test
  def test_message_properly_formatted
    assert_equal "User: Failed to request blah", 
                  Multiconnect::Error::UnsuccessfulRequest.new(class: User, action: "blah").message
  end
end