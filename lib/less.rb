require 'execjs'
require 'less/errors'
require 'less/parser'
require 'less/version'
require 'less/defaults'

module Less
  extend Less::Defaults

  def self.compile(css, options = {})
    Parser.new(options).parse(css).to_css
  end

  def self.lib_paths
    [
      File.expand_path('../less/js/less/lib', __FILE__),
      File.expand_path('../less/js/node-mime', __FILE__),
      File.expand_path('../less/js', __FILE__)
    ]
  end

  # Exports the `.node_modules` folder on the working directory so npm can
  # require modules installed locally.
  ENV['NODE_PATH'] = "#{File.expand_path('node_modules')}:#{lib_paths.join(':')}:#{ENV['NODE_PATH']}"
end
