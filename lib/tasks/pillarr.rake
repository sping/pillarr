namespace :pillarr do
  def pillarr_run_lock
    lock_file = Pillarr.configuration.lock_file
    if lock_file.nil? || lock_file == false
      Pillarr.info 'lock_file disabled'
      return yield
    end

    require 'pathname'
    path = Pathname.new(lock_file)
    mkdir_p path.dirname unless path.dirname.directory?
    file = path.open('w')
    if file.flock(File::LOCK_EX | File::LOCK_NB) == false
      Pillarr.error 'process already running, skipping'
      return
    end
    yield
  end

  desc 'collect'
  task collect: :environment do
    pillarr_run_lock do
      Pillarr::Collector.run
    end
  end
end
