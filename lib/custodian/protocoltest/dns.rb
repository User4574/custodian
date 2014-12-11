require 'custodian/settings'
require 'resolv'

#
#  The DNS-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### DNSHOSTS must run dns for bytemark.co.uk resolving NS as '80.68.80.26,85.17.170.78,80.68.80.27'.
###
#
#  The test will fail if the results are not *exactly* as specified.  i.e. If there are too
# many results, or too few, we'll alert.
#
#
module Custodian

  module ProtocolTest

    class DNSTest < TestFactory


      #
      # The line from which we were constructed.
      #
      attr_reader :line

      #
      # Name to resolve, type to resolve, and expected results
      #
      attr_reader :resolve_name, :resolve_type, :resolve_expected



      #
      # Constructor
      #
      def initialize( line )

        #
        #  Save the line
        #
        @line = line

        #
        # Is this test inverted?
        #
        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end

        if ( line =~ /for\s+([^\s]+)\sresolving\s([A-Z]+)\s+as\s'([^']+)'/ )
          @resolve_name     = $1.dup
          @resolve_type     = $2.dup
          @resolve_expected = $3.dup.downcase.split(/[\s,]+/)
        end

        #
        #  Ensure we had all the data.
        #
        raise ArgumentError, "Missing host to resolve" unless( @resolve_name )
        raise ArgumentError, "Missing type of record to lookup" unless( @resolve_type )
        raise ArgumentError, "Missing expected results" unless( @resolve_expected )
        raise ArgumentError, "Uknown record type: #{@resolve_type}" unless( @resolve_type =~ /^(A|NS|MX|AAAA)$/ )

        #
        #  The host to query against
        #
        @host = line.split( /\s+/)[0]

      end




      #
      # Allow this test to be serialized.
      #
      def to_s
        @line
      end




      #
      # Run the test.
      #
      def run_test

        # Reset the result in case we've already run
        @error = nil

        #
        # Get the timeout period.
        #
        settings = Custodian::Settings.instance()
        period   = settings.timeout()

        #
        # Do the lookup
        #
        results = resolve_via( @host,  resolve_type, resolve_name, period )
        return false if ( results.nil? )

        #
        # OK we have an array of results.  If every one of the expected
        # results is contained in those results returned then we're good.
        #

        if ( !(results - @resolve_expected).empty? or !(@resolve_expected - results).empty? )
          @error = "DNS server *#{@host}* returned the wrong records for `#{resolve_name} IN #{resolve_type}`.\n\nWe expected:\n * #{resolve_expected.join("\n * ")}\n\nWe got:\n * #{results.join("\n * ")}\n"
        end

        return @error.nil?
      end



      #
      # Resolve an IP
      #
      def resolve_via( server, ltype, name, period )

        results = Array.new()

        begin
          timeout( period ) do

            begin
              Resolv::DNS.open(:nameserver=>[server]) do |dns|
                case ltype

                when /^A$/ then
                  dns.getresources(name, Resolv::DNS::Resource::IN::A).map{ |r| results.push( r.address.to_s().downcase ) }

                when /^AAAA$/ then
                  dns.getresources(name, Resolv::DNS::Resource::IN::AAAA).map{ |r| results.push( r.address.to_s().downcase ) }

                when /^NS$/ then
                  dns.getresources(name, Resolv::DNS::Resource::IN::NS).map{ |r| results.push( Resolv.getaddresses( r.name.to_s().downcase ) ) }

                when /^MX$/ then
                  dns.getresources(name, Resolv::DNS::Resource::IN::MX).map{ |r| results.push( Resolv.getaddresses( r.exchange.to_s().downcase ) ) }
                else
                  @error = "Unknown record type to resolve: '#{ltype}'"
                  return nil
                end
              end

            rescue StandardError => x
              @error = "Exception was received when resolving : #{x}"
              return nil
            end

          end
        rescue Timeout::Error => e
          @error = "Timed-out performing DNS lookups #{e}"
          return nil
        end

        #
        # Flatten, sort, uniq
        #
        results.flatten.sort.uniq
      end



      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "dns"



    end
  end
end
