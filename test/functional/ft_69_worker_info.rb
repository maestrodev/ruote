
#
# testing ruote
#
# Sun Sep 18 10:54:00 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtWorkerInfoTest < Test::Unit::TestCase
  include FunctionalBase

  def test_empty_worker_info

    assert_nil @dashboard.worker_info
  end

  def test_worker_info

    #@dashboard.noisy = true

    3.times {
      @dashboard.launch(Ruote.define do
        10.times { echo 'hello' }
      end)
    }
    @dashboard.wait_for(3)

    info = @dashboard.worker_info

    assert_equal(
      "#{Ruote.local_ip}/#{$$}",
      info.keys.first)
    assert_equal(
      %w[
        class hostname ip pid
        processed_last_hour processed_last_minute
        put_at system uptime
        wait_time_last_hour wait_time_last_minute
      ],
      info.values.first.keys.sort)
  end
end
