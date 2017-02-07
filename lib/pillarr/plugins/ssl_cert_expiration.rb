# inspired by: https://github.com/scoutapp/scout-plugins/tree/master/ssl_cert_expiration
module Pillarr
  module Plugins
    class SslCertExpiration < Pillarr::Plugin
      OPTIONS = <<-EOS
        certs: []
      EOS

      needs 'openssl'

      def collect_data
        @today = Time.now
        if option(:certs).nil? || option(:certs).empty?
          return error('Please specify one or more certs paths')
        end

        option(:certs).each do |cert|
          check_certificate(cert)
        end
      end

      private

      def check_certificate(cert)
        unless File.exist?(cert)
          return error("Error processing cert [#{cert}] - FILE NOT FOUND")
        end

        report_key = cert.split('/').last
        certificate = OpenSSL::X509::Certificate.new(File.read(cert))
        expiration = ((Time.at(certificate.not_after) - Time.at(@today)) / 60 / 60 / 24).to_i
        report(report_key, {
          expired: expiration <= 0,
          days: expiration
        })
      rescue Exception => e
        error("Error processing cert [#{cert}]", e)
      end
    end
  end
end
