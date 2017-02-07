# inspired by: https://github.com/scoutapp/scout-plugins/tree/master/passenger
module Pillarr
  module Plugins
    class Passenger < Pillarr::Plugin
      OPTIONS = <<-EOS
        passenger_status_command: passenger-status
      EOS

      def report_template
        {
          max_pool_size: 0,
          process_current: 0,
          queue_depth: 0
        }
      end

      def collect_data
        collect_passenger_status
      end

      private

      def collect_passenger_status
        cmd  = option(:passenger_status_command) || 'passenger-status'
        data = `#{cmd} 2>&1`
        unless $?.success?
          return error("Could not get data from command: #{cmd}. Error:  #{data}")
        end

        # Passenger < 4 and passenger >= 4 report different stats. This loop extracts both formats.
        data.each_line do |line|
          if line =~ /^max\s+=\s(\d+)/
            report(:max_pool_size, $1.to_i)
          elsif line =~ /^count\s+=\s(\d+)/
            report(:process_current, $1.to_i)
          elsif line =~ /^active\s+=\s(\d+)/
            report(:process_active, $1.to_i)
          elsif line =~ /^inactive\s+=\s(\d+)/
            report(:process_inactive, $1.to_i)
          elsif line =~ /^Waiting on global queue: (\d+)/
            report(:queue_depth, $1.to_i)
          elsif line =~ /^Max pool size +: (\d+)/ # passenger 4
            report(:max_pool_size, $1.to_i)
          elsif line =~ /^Processes  +: (\d+)/   # passenger 4
            report(:process_current, $1.to_i)
          elsif line =~ /^\s+Requests in queue: (\d+)/  # passenger 4
            report(:queue_depth, $1.to_i)
          end
        end
      end
    end
  end
end
