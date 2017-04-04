module Pillarr
  module Plugins
    class Passenger < Pillarr::Plugin
      OPTIONS = <<-EOS
        passenger_status_command: sudo /usr/bin/passenger-status
      EOS

      needs 'rexml/document'

      def report_template
        {
          version: 'unkown',
          total_apps: 0,
          max_pool_size: 0,
          used_pool_size: 0,
          wait_list_size: 0,
          apps: []
        }
      end

      def collect_data
        collect_passenger_status
      end

      private

      def collect_passenger_status
        # since version: 5.0.7 we can use the xml containing more info
        cmd  = option(:passenger_status_command) || 'sudo /usr/bin/passenger-status'
        data = `#{cmd} --show=xml 2>&1`
        unless $?.success?
          return error("Could not get data from command: #{cmd}. Error:  #{data}")
        end

        xml = REXML::Document.new(data)
        version = xml.elements['info/passenger_version'].text rescue 'unkown'
        total_apps = xml.elements['info/group_count'].text.to_i rescue 'unkown'
        max_pool_size = xml.elements['info/max'].text.to_i rescue 0
        used_pool_size = xml.elements['info/capacity_used'].text.to_i rescue 0
        wait_list_size = xml.elements['info/get_wait_list_size'].text.to_i rescue 0

        report(:version, version)
        report(:total_apps, total_apps)
        report(:max_pool_size, max_pool_size)
        report(:used_pool_size, used_pool_size)
        report(:wait_list_size, wait_list_size)

        apps = {}
        xml.root.each_element("/info/supergroups/*") do |e|
          key = e.elements['group/app_root'].text[1..-1].gsub('/', '_')
          apps[key] = {
            path: e.elements['group/app_root'].text,
            wait_list_size: e.elements['get_wait_list_size'].text.to_i,
            used_pool_size: e.elements['capacity_used'].text.to_i
          }
        end
        report(:apps, apps)
      rescue => e
        error(e.message, e)
      end
    end
  end
end
