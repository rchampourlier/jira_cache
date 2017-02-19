# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jira_cache/version"

Gem::Specification.new do |spec|
  spec.name          = "jira_cache"
  spec.version       = JiraCache::VERSION
  spec.authors       = ["Romain Champourlier"]
  spec.email         = ["pro@rchampourlier.com"]
  spec.summary       = "Fetches data from JIRA and caches it in a local database."
  spec.homepage      = "https://github.com/rchampourlier/jira_cache"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting "allowed_push_host", or
  # delete this section to allow pushing this gem to any host.
  unless spec.respond_to?(:metadata)
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| f.sub(/^bin\//, '') }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "i18n"
  spec.add_dependency "activesupport-inflector"
  spec.add_dependency "pg"
  spec.add_dependency "sequel"
  spec.add_dependency "sequel_pg"
  spec.add_dependency "rest-client"
  spec.add_dependency "sinatra"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "dotenv"
end
