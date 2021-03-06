require 'socket'
require 'timeout'

#
#  The graphite-alerter.
#
#  This only exists to record timing durations in the local
# graphite/carbon instance.  Updates are sent via UDP
# to localhost:2003.
#
module Custodian

  module Alerter

    class GraphiteAlert < AlertFactory

      #
      # The test this alerter cares about
      #
      attr_reader :test


      #
      # Constructor - save the test-object away.
      #
      def initialize(obj)
        @test = obj
      end



      #
      # NOP.
      #
      def raise
      end



      #
      # NOP.
      #
      def clear
      end



      #
      # Send the test test-duration to graphite/carbon
      #
      def duration(ms)

        #
        # hostname + test-type
        #
        host = @test.target.gsub(/[\/\\.]/, '_')
        test = @test.get_type

        #
        # The payload
        #
        payload = "custodian.#{test}.#{host}.test_duration_ms #{ms} #{Time.now.to_i}\n"

        #
        #  Send metrics via TCP.
        #
        begin
          Timeout.timeout(10) do
            begin
              socket = TCPSocket.new(@target,2003)
              puts payload
              socket.write(payload)
              socket.flush
              socket.close
            rescue Errno::ENETUNREACH
              puts("Metrics host unreachable: #{e}")
            rescue StandardError => e
              puts("Error submitting metrics: #{e}")
            end
          end
        rescue Timeout::Error
          puts('Timeout submitting metrics')
        end
      end

      register_alert_type 'graphite'


    end
  end
end
