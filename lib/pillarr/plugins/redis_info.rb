# inspired by: https://github.com/scoutapp/scout-plugins/tree/master/redis-info
module Pillarr
  module Plugins
    class RedisInfo < Pillarr::Plugin
      OPTIONS = <<-EOS
        host: localhost
        port: 6379
        socket_path:
        db: 0
        password:
      EOS

      needs 'redis', 'yaml'

      def report_template
        {
          up: false,
          uptime: '',
          uptime_in_seconds: 0,
          used_memory_in_mb: 0,
          role: '',
          hits_per_sec: 0,
          misses_per_sec: 0,
          connections_per_sec: 0,
          commands_per_sec: 0,
          hits: 0,
          misses: 0,
          changes_since_last_save: nil,
          connected_clients: nil,
          connected_slaves: nil,
          bgsave_in_progress: nil
        }
      end

      def b_to_mb(bytes)
        bytes && bytes.to_f / 1024 / 1024
      end

      def seconds_to_date_string(t)
        mm, ss = t.divmod(60)            #=> [4515, 21]
        hh, mm = mm.divmod(60)           #=> [75, 15]
        dd, hh = hh.divmod(24)           #=> [3, 3]
        "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
      end

      def collect_data
        if option(:socket_path) and option(:socket_path).length > 0
          redis = Redis.new :path     => option(:socket_path),
                            :db       => option(:db),
                            :password => option(:password)
        else
          redis = Redis.new :port     => option(:port),
                            :db       => option(:db),
                            :password => option(:password),
                            :host     => option(:host)
        end

        info = redis.info

        report(:uptime, seconds_to_date_string(info['uptime_in_seconds'].to_f))
        report(:uptime_in_seconds, info['uptime_in_seconds'].to_f)
        report(:used_memory_in_mb, b_to_mb(info['used_memory']))
        report(:role, info['role'])
        report(:up, true)

        report(:hits_per_sec, info['keyspace_hits'].to_i)
        report(:misses_per_sec, info['keyspace_misses'].to_i)

        report(:connections_per_sec, info['total_connections_received'].to_i)
        report(:commands_per_sec, info['total_commands_processed'].to_i)

        report(:hits, info['keyspace_hits'].to_i)
        report(:misses, info['keyspace_misses'].to_i)

        if info['role'] == 'slave'
          master_link_status = case info['master_link_status']
                               when 'up' then 1
                               when 'down' then 0
                               end
          report(:master_link_status, master_link_status)
          report(:master_last_io_seconds_ago, info['master_last_io_seconds_ago'])
          report(:master_sync_in_progress, info['master_sync_in_progress'])
        end

        # General Stats
        %w(changes_since_last_save connected_clients connected_slaves bgsave_in_progress).each do |key|
          report(key, info[key])
        end
      rescue Redis::BaseConnectionError
        return error('Could not connect to Redis.')
      end
    end
  end
end
