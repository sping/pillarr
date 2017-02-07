require 'logger'

class PillarrLogger < Logger
  attr_reader :messages

  def initialize(*args)
    super
  end

  def add(severity, message=nil, progname = nil, &block)
    super
  end
end
