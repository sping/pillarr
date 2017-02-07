module Pillarr
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/pillarr.rake'
    end
  end
end
