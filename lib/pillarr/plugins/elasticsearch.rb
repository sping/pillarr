# inspired by: https://github.com/scoutapp/scout-plugins/blob/master/elasticsearch_node_status
module Pillarr
  module Plugins
    class Elasticsearch < Pillarr::Plugin
      OPTIONS = <<-EOS
        host: http://127.0.0.1
        port: 9200
        node_name: _local
        username:
        password:
      EOS

      needs 'net/http', 'net/https', 'json', 'cgi', 'open-uri'

      def report_template
        {
          status: '',
          number_of_nodes: 0,
          number_of_data_nodes: 0,
          active_primary_shards: 0,
          active_shards: 0,
          relocating_shards: 0,
          initializing_shards: 0,
          unassigned_shards: 0,
          node_info: {
            node_name: '',
            size_of_indices: 0,
            num_docs: 0,
            open_file_descriptors: 0,
            heap_used: 0,
            heap_committed: 0,
            non_heap_used: 0,
            non_heap_committed: 0,
            threads_count: 0
          }
        }
      end

      def collect_data
        if option(:host).nil? || option(:port).nil?
          return error("The elasticsearch host and port are required. Host: #{option(:host)} Port: #{option(:port)}")
        end
        if option(:username).nil? != option(:password).nil?
          return error("Both the elasticsearch username and password to monitor the protected cluster are required.")
        end

        collect_health_data
        collect_node_info
      end

      def collect_health_data
        base_url = "#{option(:host)}:#{option(:port)}/_cluster/health"

        resp = get_response(base_url)
        response = JSON.parse(resp.body)

        report(:status, status(response['status']))
        report(:number_of_nodes, response['number_of_nodes'])
        report(:number_of_data_nodes, response['number_of_data_nodes'])
        report(:active_primary_shards, response['active_primary_shards'])
        report(:active_shards, response['active_shards'])
        report(:relocating_shards, response['relocating_shards'])
        report(:initializing_shards, response['initializing_shards'])
        report(:unassigned_shards, response['unassigned_shards'])

      rescue OpenURI::HTTPError
        error("Please ensure the base url for elasticsearch is correct.")
      rescue SocketError, Errno::ECONNREFUSED, URI::InvalidURIError
        error("Unable to connect - Please ensure the host and port are correct. Host: #{option(:host)} Port: #{option(:port)}")
      rescue Exception => e
        error(e.message, e)
      end

      def collect_node_info
        base_url = "#{option(:host)}:#{option(:port)}/_nodes/#{node_name}/stats?all=true"

        response = get_response(base_url)
        resp = JSON.parse(response.body)

        if resp['nodes'].nil? or resp['nodes'].empty?
          return error("No node found with the specified name", "No node in the cluster could be found with the specified name.\n\nNode Name: #{node_name}")
        end

        response = resp['nodes'].values.first
        # newer ES puts memory in ['indices']['store']['size_in_bytes']
        mem = if response['indices']['store']
          response['indices']['store']['size_in_bytes']
        else
          response['indices']['size_in_bytes']
        end

        report(:node_info, {
          node_name: node_name,
          size_of_indices: b_to_mb(mem) || 0,
          num_docs: (response['indices']['docs']['count'] rescue 0),
          open_file_descriptors: response['process']['open_file_descriptors'] || 0,
          heap_used: b_to_mb(response['jvm']['mem']['heap_used_in_bytes'] || 0),
          heap_committed: b_to_mb(response['jvm']['mem']['heap_committed_in_bytes'] || 0),
          non_heap_used: b_to_mb(response['jvm']['mem']['non_heap_used_in_bytes'] || 0),
          non_heap_committed: b_to_mb(response['jvm']['mem']['non_heap_committed_in_bytes'] || 0),
          threads_count: response['jvm']['threads']['count'] || 0,
        })
      rescue OpenURI::HTTPError
        error("Please ensure the base url for elasticsearch is correct.")
      rescue SocketError, Errno::ECONNREFUSED, URI::InvalidURIError
        error("Unable to connect - Please ensure the host and port are correct. Host: #{option(:host)} Port: #{option(:port)}")
      rescue Exception => e
        error(e.message, e)
      end

      private

      def get_response(base_url)
        uri = URI.parse(base_url)
        # raise OpenURI::HTTPError.new('adsf', 'asdf')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.start { |h|
          req = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
          if !option(:username).nil? && !option(:password).nil?
            req.basic_auth option(:username), option(:password)
          end
          response = h.request(req)
        }
      end

      def b_to_mb(bytes)
        bytes && bytes.to_f / 1024 / 1024
      end

      def node_name
        name = option(:node_name).to_s.strip.empty? ? "_local" : option(:node_name)
        CGI.escape(name.strip)
      end

      # Generates a status string like "2 (green)" so triggers can be run off the status.
      def status(color)
        code = case color
        when 'green'
          2
        when 'yellow'
          1
        when 'red'
          0
        end
        "#{code} (#{color})"
      end
    end
  end
end
