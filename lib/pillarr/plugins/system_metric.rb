module Pillarr
  module Plugins
    class SystemMetric < Pillarr::Plugin
      needs 'server_metrics'

      def report_template
        {
          disks: {},
          cpu: {},
          memory: {},
          network: {},
          processes: {}
        }
      end

      def collect_data
        collect_system_info
        collect_metrics
      end

      def collect_system_info
        report(:system_info, ServerMetrics::SystemInfo.to_h)
      rescue Exception => e
        error(e.message, e)
      end

      def collect_metrics
        results = {}
        report(:disks, ServerMetrics::Disk.new.run)
        report(:cpu, ServerMetrics::Cpu.new.run)
        report(:memory, ServerMetrics::Memory.new.run)
        report(:network, ServerMetrics::Network.new.run)
        report(:processes, ServerMetrics::Processes.new(ServerMetrics::SystemInfo.num_processors).run)
      rescue Exception => e
        error(e.message, e)
      end
    end
  end
end
