require 'rubygems'
require 'yaml'
require 'erb'
require 'server_metrics'
require 'timeout'
require 'parallel'

require 'active_support/inflector'

require 'pillarr/version'
require 'pillarr/config'
require 'pillarr/pillarr_logger'
require 'pillarr/plugin'
require 'pillarr/collector'
require 'pillarr/railtie' if defined?(Rails)

module Pillarr
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Pillarr::Config.new
      yield(configuration)
      self.configuration.setup
    end

    def logger
      self.configuration.logger
    end

    def debug msg
      logger.debug("[Pillarr]") { msg }
    end

    def info msg
      logger.info("[Pillarr]") { msg }
    end

    def warn msg
      logger.warn("[Pillarr]") { msg }
    end

    def error msg
      logger.error("[Pillarr]") { msg }
    end

    def fatal msg
      logger.fatal("[Pillarr]") { msg }
    end
  end
end
