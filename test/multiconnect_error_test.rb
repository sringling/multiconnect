require 'minitest_helper'

class MulticonnectErrorTest < Minitest::Test
  def test_message_properly_formatted
    assert_equal "User: Failed to request blah", 
                  Multiconnect::Error::UnsuccessfulRequest.new(class: User, action: "blah").message
  end

  def test_message_can_include_inner_details
    assert_equal "User: Failed to request blah - I segfaulted, I timed out on localhost:3000",
                 Multiconnect::Error::UnsuccessfulRequest.new(class: User, action: "blah", errors: errors).message
  end

  private

  def errors
    [Exception.new('I segfaulted'), Exception.new('I timed out on localhost:3000')]
  end

end