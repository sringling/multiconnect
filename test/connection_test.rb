require 'minitest_helper'

class ConnectionTest < Minitest::Test
  def test_base_connection_raises_on_critical_methods
    assert_raises NotImplementedError do
      Multiconnect::Connection::Base.new.report_error(nil)
    end

    assert_raises NotImplementedError do
      Multiconnect::Connection::Base.new.request(:lol, [:nope])
    end
  end

  def test_connections_can_make_valid_requests
    assert SecondaryConnection.new.request(:find, 6)
  end

  def test_connections_ignore_excepted_requests
    assert SecondaryConnection.new.execute(:find, 6).success?
    refute SecondaryConnection.new(except: :find).execute(:find, 6).success?
    refute SecondaryConnection.new(except: [:find]).execute(:find, 6).success?
  end

  def test_connections_filter_non_only_requests
    assert SecondaryConnection.new.execute(:find, 6).success?
    assert SecondaryConnection.new(only: :find).execute(:find, 6).success?
    refute SecondaryConnection.new(only: :where).execute(:find, 6).success?
    assert SecondaryConnection.new(only: [:find]).execute(:find, 6).success?
    refute SecondaryConnection.new(only: [:where]).execute(:find, 6).success?

    refute SecondaryConnection.new(only: [:find], except: :find).execute(:find, 6).success?
  end

  def test_connection_responds_to_client
    assert_equal DummyObject, PrimaryConnection.new(client: DummyObject).client
  end
end
