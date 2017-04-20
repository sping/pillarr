module Pillarr
  class Config
    attr_accessor :logger

    attr_accessor :collectors

    attr_accessor :collector_instances

    attr_accessor :output_file

    attr_accessor :lock_file

    def initialize
      self.collectors ||= Hash.new
      self.collector_instances ||= []
      self.lock_file ||= '/tmp/pillar.cron.lock'
      self.logger ||= setup_logger
    end

    def setup
      collectors = YAML::load(ERB.new("#{self.collectors}").result)
      return if collectors.nil? || collectors.empty?
      collectors.each_pair do |file_name, options|
        plugin_instance = Pillarr::Plugin.setup(file_name, options || {})
        next if plugin_instance.nil?
        self.collector_instances << plugin_instance
      end
    end

    private

    def setup_logger
      logger = PillarrLogger.new($stdout)
      logger.datetime_format = "%Y-%m-%d %H:%M:%S "
      logger.level = level
      logger
    end

    def level
      Logger.const_get(@level.upcase) rescue Logger::INFO
    end
  end
end
