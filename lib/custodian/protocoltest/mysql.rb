require 'custodian/protocoltest/tcp'

#
#  The MySQL-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run mysql otherwise 'database fail'.
###
#
#  The specification of the port is optional.
#
module Custodian

  module ProtocolTest

    class MySQLTest < TCPTest

      #
      # Constructor
      #
      # Ensure we received a port to run the test against.
      #
      def initialize( line )

        #
        # Save the line
        #
        @line = line

        #
        # Save the host
        #
        @host  = line.split( /\s+/)[0]


        #
        # Is this test inverted?
        #
        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end


        #
        # Save the port
        #
        if ( line =~ /on\s+([0-9]+)/ )
          @port = $1.dup
        else
          @port = 3306
        end
      end




      #
      # Allow this test to be serialized.
      #
      def to_s
        return( @line )
      end




      #
      # Run the test.
      #
      def run_test

        # reset the error, in case we were previously executed.
        @error = nil

        run_test_internal( @host, @port )
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "mysql"



    end
  end
end