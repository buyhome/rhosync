require 'templater/spec/helpers'

require File.join(File.dirname(__FILE__),'..','..','generators','rhosync')

Spec::Runner.configure do |config|
  config.include Templater::Spec::Helpers
end