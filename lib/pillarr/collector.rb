module Pillarr
  class Collector
    class << self
      def run
        collector = new
        collector.collect
        collector.write!
      end
    end

    def initialize
      prepare_data
    end

    def collect
      prepare_data
      collect_plugin_data
      finalize
    end

    def write!
      return if Pillarr.configuration.output_file.nil?
      File.open(Pillarr.configuration.output_file, 'w') do |file|
        file.truncate(0)
        file.write(raw_data.to_json)
      end
    end

    def print
      puts raw_data.inspect
    end

    def raw_data
      @data
    end

    private

    def prepare_data
      @started = Time.now
      @data = {
        _timestamp: Time.now.to_i
      }
    end

    def finalize
      @data[:_runtime]= (Time.now - @started)
    end

    def collect_plugin_data
      results = Parallel.map(Pillarr.configuration.collector_instances) do |plugin|
        plugin.run
      end
      @data = results.reduce(@data, :merge)
    end
  end
end
