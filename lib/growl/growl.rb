
module Growl
  
  BIN = 'growlnotify'
  
  #--
  # Exceptions
  #++
  
  class Error < StandardError; end
  
  #--
  # Singleton methods
  #++
  
  module_function
  
  ##
  # Execute +args+ against the binary.
  
  def exec *args
    Kernel.system BIN, *args
  end
  
  ##
  # Return the version triple of the binary.
  
  def version
    @version ||= `#{BIN} --version`.split[1]
  end
  
  ##
  # Check if the binary is installed and accessable.
  
  def installed?
    !! version
  end
  
  ##
  # Return an instance of Growl::Base or nil when not installed.
  
  def new *args, &block
    return unless installed?
    Base.new *args, &block
  end
  
  #--
  # Growl base
  #++
  
  class Base
    attr_reader :args
    
    ##
    # Initialize with optional +block+, which is then
    # instance evaled or yielded depending on the blocks arity.
    
    def initialize options = {}, &block
      @args = []
      if block_given?
        if block.arity > 0
          yield self
        else
          self.instance_eval &block
        end
      else
        options.each do |key, value|
          send :"#{key}=", value
        end
      end
    end
    
    ##
    # Run the notification, only --message is required.
    
    def run
      raise Error, 'message required' unless message
      self.class.switches.each do |switch|
        if send(:"#{switch}?")
          args << "--#{switch}"
          args << send(switch) if send(switch).is_a? String
        end
      end
      Growl.exec *args
    end
    
    ##
    # Define a switch +name+.
    #
    # === examples
    #
    #  switch :sticky
    #
    #  @growl.sticky!
    #  @growl.sticky?         # => true
    #  @growl.sticky = false
    #  @growl.sticky?         # => false
    #
    
    def self.switch name
      ivar = :"@#{name}"
      (@switches ||= []) << name
      define_method(:"#{name}")  { instance_variable_get(ivar) }
      define_method(:"#{name}=") { |value| instance_variable_set(ivar, value) }
      define_method(:"#{name}?") { !! instance_variable_get(ivar) }
      define_method(:"#{name}!") { instance_variable_set(ivar, true) }
    end
    
    ##
    # Return array of available switch symbols.
    
    def self.switches
      @switches
    end
    
    #--
    # Switches
    #++
    
    switch :title
    switch :message
    switch :sticky
    switch :name
    switch :appIcon
    switch :icon
    switch :iconpath
    switch :image
    switch :priority
    switch :identifier
    switch :host
    switch :password
    switch :udp
    switch :port
    switch :auth
    switch :crypt

  end

end

def Growl options = {}, &block
  return unless Growl.installed?
  Growl.new(options, &block).run
end