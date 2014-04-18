require 'thor/group'
require 'yaml'

class ActiveMerchantGenerator < KillbillGenerator
  source_root File.expand_path('..', __FILE__)

  def generate
    render_templates '/templates/{*,.*}.rb', ['config.yml', 'plugin.gemspec'], nil, false
    template 'templates/config.yml.rb', "#{output_path}/#{identifier}.yml"
    template 'templates/plugin.gemspec.rb', "#{output_path}/killbill-#{identifier}.gemspec"

    render_templates '/templates/lib/{*,.*}.rb', ['plugin.rb'], "lib/#{identifier}"
    template 'templates/lib/plugin.rb', "#{output_path}/lib/#{identifier}.rb"

    render_templates '/templates/lib/models/{*,.*}.rb', [], "lib/#{identifier}/models"

    copy_file 'templates/lib/views/form.erb', "#{output_path}/lib/#{identifier}/views/form.erb"

    template 'templates/db/ddl.sql.rb', "#{output_path}/db/ddl.sql"
    template 'templates/db/schema.rb', "#{output_path}/db/schema.rb"

    template 'templates/spec/spec_helper.rb', "#{output_path}/spec/spec_helper.rb"
    template 'templates/spec/base_plugin_spec.rb', "#{output_path}/spec/#{identifier}/base_plugin_spec.rb"
    template 'templates/spec/integration_spec.rb', "#{output_path}/spec/#{identifier}/remote/integration_spec.rb"
  end

  protected

  def render_templates(glob, to_exclude = [], extra_dir = nil, keep_rb_extension = true)
    Dir[File.dirname(__FILE__) + glob].each do |f|
      filename = File.basename(f, keep_rb_extension ? '' : '.rb')

      next if to_exclude.include? filename

      template f, extra_dir ? "#{output_path}/#{extra_dir}/#{filename}" : "#{output_path}/#{filename}"
    end
  end
end
