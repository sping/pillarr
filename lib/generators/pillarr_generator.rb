class PillarrGenerator < Rails::Generators::Base
  # Adds current directory to source paths, so we can find the template file.
  source_root File.expand_path('..', __FILE__)

  desc 'Configures Pilarr'
  def generate_layout
    template 'pillarr_initializer.rb.erb', 'config/initializers/pillarr.rb'
  end
end
