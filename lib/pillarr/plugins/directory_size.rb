# inspired by: https://github.com/scoutapp/scout-plugins/blob/master/directory_size
module Pillarr
  module Plugins
    class DirectorySize < Pillarr::Plugin
      OPTIONS = <<-EOS
        paths: []
      EOS

      def collect_data
        if option(:paths).nil? || option(:paths).empty?
          return error("Please specify one or more paths")
        end

        option(:paths).each do |path|
          collect_path_info(path)
        end
      end

      private

      def collect_path_info(path)
        output = `du -s #{path}/ 2>&1`
        if !$?.success?
          return error("Error fetching directory size for [#{path}]")
        end
        size_in_bytes = output.split("\n").last.split("\t").first.to_i
        report(path, {
          bytes: size_in_bytes,
          megabytes: to_mb(size_in_bytes)
        })
      end

      def to_mb(bytes)
        bytes && bytes.to_f / 1024
      end
    end
  end
end
