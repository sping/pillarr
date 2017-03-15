# inspired by: https://github.com/scoutapp/scout-plugins/blob/master/apache_analyzer/apache_analyzer.rb
module Pillarr
  module Plugins
    class RequestLogAnalyzer < Pillarr::Plugin
      OPTIONS = <<-EOS
        format: %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"
        log: /var/log/apache2/access.log
        minutes_to_analyze: 5
      EOS

      needs 'elif', 'request_log_analyzer'

      def report_template
        {
          processed_requests: 0,
          timestamps: {
            first: nil,
            last: nil
          },
          methods: {
            get: 0,
            post: 0,
            put: 0,
            patch: 0,
            delete: 0,
            options: 0
          },
          timing: {
            min: nil,
            max: nil,
            avg: nil,
            percentile_99: nil,
            percentile_95: nil,
            percentile_90: nil
          },
          log: nil,
          minutes_to_analyze: 0
        }
      end

      def collect_data
        patch
        setup_success = setup

        # always report log, and minutes to analyze
        report(:minutes_to_analyze, minutes_to_analyze)
        report(:log, @log)

        return if setup_success == false

        report(:processed_requests, @requests.count)

        first_timestamp = @requests.last[:timestamp] rescue nil
        last_timestamp = @requests.first[:timestamp] rescue nil
        report(:timestamps, {
          first: first_timestamp,
          last: last_timestamp
        })

        status_codes = @requests.group_by{|a| a[:http_status]}.collect do |status, requests|
          { "#{status}": requests.count }
        end.inject({}) do |methods, result|
          methods[result.keys[0].to_sym] = result.values[0]
          methods
        end
        report(:status_codes, all_status_codes.merge(status_codes))

        request_methods = report_template[:methods]
        request_methods = @requests.group_by{|a| a[:http_method]}.collect do |http_method, requests|
          { "#{http_method.downcase}": requests.count }
        end.inject(request_methods) do |methods, result|
          methods[result.keys[0].to_sym] = result.values[0]
          methods
        end
        report(:methods, request_methods)

        durations = @requests.map{|a|a[:duration]}.compact
        timing = {
          min: durations.min,
          max: durations.max,
          avg: (durations.inject{ |sum, el| sum + el }.to_f / durations.size),
          percentile_99: percentile(durations, 99),
          percentile_95: percentile(durations, 95),
          percentile_90: percentile(durations, 90)
        }
        report(:timing, timing)
      end

      def setup
        @minutes_ago_timestamp = (Time.now - minutes_to_analyze * 60).strftime('%Y%m%d%H%M%S').to_i
        # @minutes_ago_timestamp = Time.new(2014, 2, 17, 6, 38, 25).strftime('%Y%m%d%H%M%S').to_i
        # request log analyzer
        @line_definition  = ::RequestLogAnalyzer::FileFormat::Apache.access_line_definition(option(:format))
        @request          = ::RequestLogAnalyzer::FileFormat::Apache.new.request
        # log
        @log = option(:log)

        unless File.exist?(@log)
          error("Error processing log [#{@log}] - FILE NOT FOUND")
          return false
        end

        # if file is empty (might be because of logrotate) return without error
        if File.zero?(@log)
          return false
        end

        unless read_and_parse_log
          error("Error processing log [#{@log}] - NO MATCHES FOUND FOR FORMAT")
          return false
        end
        true
      end

      private

      def read_and_parse_log
        @requests = []
        found_a_match = false
        Elif.foreach(@log) do |line|
          if matches = @line_definition.matches(line)
            found_a_match = true
            result = @line_definition.convert_captured_values(matches[:captures], @request)
            if timestamp = result[:timestamp]
              if timestamp < @minutes_ago_timestamp
                # we are done!
                break
              else
                @requests << result unless result.nil?
              end
            end
          end
        end
        found_a_match
      end

      def percentile(array, pcnt)
        sorted_array = array.sort
        return nil if sorted_array.length == 0
        return sorted_array.first if sorted_array.length == 1
        return sorted_array.last  if pcnt == 100

        rank = pcnt / 100.0 * (sorted_array.length - 1)
        lower, upper = sorted_array[rank.floor, 2]
        lower + (upper - lower) * (rank - rank.floor)
      end

      def minutes_to_analyze
        minutes = option(:minutes_to_analyze).to_i
        minutes = 5 if minutes == 0
        minutes
      end

      def patch
        patch_elif
        patch_rla
      end

      def patch_elif
        if Elif::VERSION < "0.2.0"
          Elif.send(:define_method, :pos) do
            @current_pos +
            @line_buffer.inject(0) { |bytes, line| bytes + line.size }
          end
        end
      end

      def patch_rla
        # override user directive incorrect matcher
        ::RequestLogAnalyzer::FileFormat::Apache::LOG_DIRECTIVES['u'] = {
          nil => {
            regexp: '(\S+|-)',
            captures: [{ name: :user, type: :nillable_string }]
          }
        }
        # add '%{IGNORE}i' directive
        ::RequestLogAnalyzer::FileFormat::Apache::LOG_DIRECTIVES['i']['IGNORE'] = {
          regexp: '(.*)', captures: [{ name: :ignore, type: :nillable_string }]
        }
      end

      # taken from Rack::Utils::HTTP_STATUS_CODES
      def all_status_codes
        {
          '100': 0,
          '101': 0,
          '102': 0,
          '200': 0,
          '201': 0,
          '202': 0,
          '203': 0,
          '204': 0,
          '205': 0,
          '206': 0,
          '207': 0,
          '208': 0,
          '226': 0,
          '300': 0,
          '301': 0,
          '302': 0,
          '303': 0,
          '304': 0,
          '305': 0,
          '307': 0,
          '308': 0,
          '400': 0,
          '401': 0,
          '402': 0,
          '403': 0,
          '404': 0,
          '405': 0,
          '406': 0,
          '407': 0,
          '408': 0,
          '409': 0,
          '410': 0,
          '411': 0,
          '412': 0,
          '413': 0,
          '414': 0,
          '415': 0,
          '416': 0,
          '417': 0,
          '421': 0,
          '422': 0,
          '423': 0,
          '424': 0,
          '426': 0,
          '428': 0,
          '429': 0,
          '431': 0,
          '451': 0,
          '500': 0,
          '501': 0,
          '502': 0,
          '503': 0,
          '504': 0,
          '505': 0,
          '506': 0,
          '507': 0,
          '508': 0,
          '510': 0,
          '511': 0
        }
      end
    end
  end
end
