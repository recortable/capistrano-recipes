require 'yaml'
require 'erb'
require 'ostruct'

filename = File.dirname(File.expand_path(__FILE__)) + '/config.yml'
config = YAML::load(File.open(filename))
erb = File.read(File.expand_path('./templates/deploy.rb.erb', File.dirname(__FILE__)))

content = ERB.new(erb).result(OpenStruct.new(config).instance_eval { binding })
output = File.dirname(File.expand_path(__FILE__)) + '/../deploy.rb'
File.open(output, 'w') { |file| file.write(content) }



