namespace :pillarr do
  desc 'collect'
  task collect: :environment do
    Pillarr::Collector.run
  end
end
