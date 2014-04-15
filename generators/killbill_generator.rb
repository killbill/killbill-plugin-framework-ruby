require "thor/group"

class KillbillGenerator < Thor::Group
  include Thor::Actions

  argument :name
  argument :dir
  class_option :destroy, :type => :boolean, :desc => 'Destroys rather than generates the template'

  def initialize(*args)
    super
  rescue Thor::InvocationError
    at_exit { print self.class.help(shell) }
    raise
  end

  protected

  def template(source, dest)
    if options[:destroy]
      remove_file dest
    else
      super
    end
  end

  def output_path
    @output_path ||= File.expand_path(dir)
  end

  def identifier
    @identifier ||= class_name.gsub(%r{([A-Z])}) { |m| "_#{$1.downcase}" }.sub(%r{^_}, '')
  end

  def class_name
    @class_name ||= name.gsub(%r{(^[a-z])|_([a-zA-Z])}) { |m| ($1||$2).upcase }
  end
end
