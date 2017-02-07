# inspired by: https://github.com/scoutapp/scout-plugins/blob/master/sidekiq_monitor
module Pillarr
  module Plugins
    class Sidekiq < Pillarr::Plugin
      needs 'redis', 'sidekiq'

      require 'rubygems'
      begin; require 'sidekiq/api'; rescue LoadError; nil; end

      OPTIONS = <<-EOS
        host: localhost
        port: 6379
        db:   0
        username:
        password:
        namespace:
      EOS

      def report_template
        {
          stats: {},
          queues: {},
          running: 0
        }
      end

      def collect_data
        setup_sidekiq
        collect_sidekiq_information
      end

      private

      def setup_sidekiq
        ::Sidekiq::Logging.logger = nil
        ::Sidekiq.configure_client do |config|
          config.redis = { url: redis_url, namespace: option(:namespace) }
        end
      end

      def collect_sidekiq_information
        begin
          stats = ::Sidekiq::Stats.new
          report(:stats, stats.as_json['stats'])
          report(:queues, stats.queues)

          ::Sidekiq.redis do |conn|
            running = conn.scard('workers').to_i
            report(:running, running)
          end
        rescue Exception => e
          error(e.message, e)
        end
      end

      def redis_url
        protocol = 'redis://'
        auth = [option(:username), option(:password)].compact.join(':')
        path = "#{option(:host)}:#{option(:port)}/#{option(:db)}"

        url = protocol
        url += auth if auth && auth != ':'
        url += path
      end
    end
  end
end
