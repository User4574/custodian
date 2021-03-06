
module Custodian


  #
  #  The result of a single test:
  #
  #  If a test returns "TEST_FAILED" an alert will be raised.
  #
  #  If a test returns "TEST_PASSED" any outstanding alert will clear.
  #
  #  If a test returns "TEST_SKIPPED" NEITHER of those things will happen.
  #
  class TestResult
    TEST_PASSED  = 2
    TEST_FAILED  = 4
    TEST_SKIPPED = 8


    #
    #  Allow one of our symbols to be converted back
    #
    def self.to_str(status)
      for sym in self.constants
        if self.const_get(sym) == status
          return sym.to_s
        end
      end
    end
  end



  #
  #
  # Base class for custodian protocol-tests
  #
  # Each subclass will register themselves, via the call
  # to 'register_test_type'.
  #
  # This class is a factory that will return the correct
  # derived class for a given line from our configuration
  # file.
  #
  #
  class TestFactory


    #
    # The subclasses we have.
    #
    @@subclasses = {}


    #
    # Create a test-type object given a line of text from our parser.
    #
    # The line will be like "target must run tcp|ssh|ftp|smtp .."
    #
    def self.create(line)


      raise ArgumentError, 'The type of test to create cannot be nil' if line.nil?
      raise ArgumentError, 'The type of test to create must be a string' unless line.kind_of? String

      #
      #  The array of tests we return.
      #
      #  This is required because a single test-definition may result in
      # multiple tests being executed.
      #
      result = []


      #
      # If this is an obvious protocol test.
      #
      if  line =~ /must\s+(not\s+)?run\s+(\S+)(\s+|\.|$)/

        test_type = $2.dup
        test_type = test_type.downcase
        test_type.chomp!('.')

        if  @@subclasses[test_type].nil?
            raise ArgumentError, "There is no handler registered for the '#{test_type}' test-type"
        end


        #
        #  For each of the test-classes that implement the type
        #
        @@subclasses[test_type].each do |impl|

          if impl
            obj = impl.new(line)

            #
            # Get the notification text, which is not specific to the test-type
            #
            # We do this only after we've instantiated the test.
            #
            if line =~ /\s+otherwise\s+'([^']+)'/
              obj.set_notification_text($1.dup)
            end


            #
            # Some tests will replace their subject.
            #
            #
            if line =~ /\s+with\s+subject\s+'([^']+)'/
              obj.set_subject($1.dup)
            else
              obj.set_subject( nil )
            end

            #
            # Is the test inverted?
            #
            obj.set_inverted(line =~ /must\s+not\s+run/ ? true : false)

            result.push(obj)
          else
            raise ArgumentError, "Bad test type: '#{test_type}'"
          end
        end

        # return the test-types.
        return(result)

      else
        raise "Failed to instantiate a suitable protocol-test for '#{line}'"
      end
    end


    #
    # Register a new test type - this must be called by our derived classes
    #
    def self.register_test_type(name)
      @@subclasses[name] ||= []
      @@subclasses[name].push(self)
    end


    #
    # Return the test-types we know about.
    #
    # i.e. Derived classes that have registered themselves.
    #
    def self.known_tests
      @@subclasses
    end


    #
    # Get the friendly-type of derived-classes
    #
    def get_type
      # get each registed type
      @@subclasses.keys.each do |name|

        # for each handler ..
        @@subclasses[name].each do |impl|
          if (impl == self.class)
            return name
          end
        end
      end
      nil
    end


    #
    # Return the target of this test.
    #
    def target
      @host
    end


    #
    # If this test has a custom subject then return it
    #
    def get_subject
      @subject
    end


    #
    # Setup a custom subject for the (mauve) alert we raise
    #
    def set_subject( subject )
      @subject = subject
    end


    #
    # Return the user-text which is returned on error
    #
    def get_notification_text
      @notification_text
    end




    #
    # Set the user-text which is returned on error.
    #
    def set_notification_text(str)
      @notification_text = str
    end




    #
    #  Is this test inverted?
    #
    def set_inverted(val)
      @inverted = val
    end

    def inverted?
      @inverted
    end



    #
    #  Return the port of this test.
    #
    def port
      @port
    end




  end

end
