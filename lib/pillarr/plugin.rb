module Pillarr
  class PluginTimeoutError < RuntimeError; end

  # Inspired by: https://github.com/scoutapp/scout-client/blob/master/lib/scout/plugin.rb
  class Plugin
    # A new class for plugin Timeout errors.
    # Default 60 seconds timeout when running collectors
    DEFAULT_COLLECTOR_TIMEOUT = 60

    class << self
      def needs(*libraries)
        if libraries.empty?
          @needs ||= [ ]
        else
          needs.push(*libraries.flatten)
        end
      end

      def setup(plugin_name, config = {})
        plugin_class = nil
        begin
          require "pillarr/plugins/#{plugin_name}"
          plugin_class = "Pillarr::Plugins::#{plugin_name.classify}".constantize
        rescue LoadError
          begin
            plugin_class = "#{plugin_name.classify}".constantize
            unless plugin_class.ancestors.include? Pillarr::Plugin
              plugin_class = nil
              Pillarr.error "Custom plugin | '#{plugin_name.classify}' doesn't inherit from Pillarr::Plugin"
            end
          rescue NameError
            plugin_class = nil
            Pillarr.error "Custom plugin | failed to load custom plugin: '#{plugin_name.classify}'"
          end
        rescue Exception => e
          Pillarr.debug "Failed creating instance from: #{plugin_name}. Message: #{e.message}"
        ensure
          return if plugin_class.nil?
          Pillarr.debug "Successfully created instance from '#{plugin_class}'"
          return plugin_class.new(config)
        end
      end
    end

    def initialize(options)
      @options = default_options.merge(options)
      reset
    end

    # NOTE: override this methods
    def report_template; {} end
    def collect_data; end

    def run
      reset
      begin
        if self.class.needs.all? { |l| library_available?(l) }
          Timeout.timeout(timeout_treshold, PluginTimeoutError) do
            collect_data
          end
        end
      rescue Timeout::Error, PluginTimeoutError
        reset(true)
        error("timed out after #{timeout_treshold} seconds")
      rescue Exception => e
        reset(true)
        error('error during collecting data', e)
      ensure
        return { key => @data }
      end
    end

    def error(message, exception=nil)
      report(:error, true)
      report(:error_messages, message)

      if exception.is_a?(Exception)
        Pillarr.error "Problem running collector [#{self.class}]: #{exception.message}: \n#{exception.backtrace.join("\n")}"
      else
        Pillarr.error "Problem running collector [#{self.class}]: #{message}}"
      end
    end

    def report(key, value)
      if @data[key.to_sym].is_a?(Array)
        @data[key.to_sym] << value
      else
        @data[key.to_sym] = value
      end
    end

    private

    def reset(keep_errors = false)
      if keep_errors && @data[:error] && @data[:error_messages]
        @data = {
          error: @data[:error],
          error_messages: @data[:error_messages],
        }.merge(report_template)
      else
        @data = {
          error: false,
          error_messages: [],
        }.merge(report_template)
      end
    end

    def default_options
      @default_options ||= YAML.load("#{self.class}::OPTIONS".constantize) rescue {}
    end

    def option(name)
      @options[name] || @options[name.is_a?(String) ? name.to_sym : String(name)]
    end

    def timeout_treshold
      option(:timeout) || DEFAULT_COLLECTOR_TIMEOUT
    end

    def key
      option(:key) || self.class.to_s.demodulize.tableize.singularize
    end

    def library_available?(library)
      begin
        require library
      rescue LoadError
        begin
          require 'rubygems'
          require library
        rescue LoadError => e
          error("Failed to load library - #{library}", e)
          return false
        end
      end
      true
    end
  end
end
