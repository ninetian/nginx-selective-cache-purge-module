require 'rubygems'
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', File.dirname(__FILE__))
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require(:default, :test) if defined?(Bundler)

require "net/http"
require "uri"

require File.expand_path('nginx_configuration', File.dirname(__FILE__))

def response_for(url)
  uri = URI.parse(url)
  Net::HTTP.get_response(uri)
end

RSpec::Matchers.define :have_purged_urls do |urls|
  match do |actual|
    text = actual.is_a?(Array) ? actual.map{|v| "\n#{v} ->"}.join : actual
    urls.all? do |url|
      text.match(/\n#{url} ->/)
    end
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would #{description}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not #{description}"
  end

  description do
    "have purged the urls: #{urls.join(", ")}"
  end
end

RSpec::Matchers.define :have_not_purged_urls do |urls|
  match do |actual|
    text = actual.is_a?(Array) ? actual.map{|v| "\n#{v} ->"}.join : actual
    urls.none? do |url|
      text.match(/\n#{url} ->/)
    end
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would not #{description}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would #{description}"
  end

  description do
    "have purged none of the urls: #{urls.join(", ")}"
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    FileUtils.rm_rf Dir[File.join(NginxTestHelper.nginx_tests_tmp_dir, "cores", "**")]
  end
  config.before(:each) do
    FileUtils.mkdir_p File.join(File.join(NginxTestHelper.nginx_tests_tmp_dir, "cores", config_id))
  end
  config.after(:each) do
    NginxTestHelper::Config.delete_config_and_log_files(config_id) if has_passed?
  end
  config.order = "random"
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
end

