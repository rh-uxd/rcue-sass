# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rcue-sass/version'

Gem::Specification.new do |spec|
  spec.name          = 'rcue-sass'
  spec.version       = RCUE::VERSION
  spec.authors       = ['Red Hat']

  spec.homepage      = 'http://rcue-uxd.itos.redhat.com/'
  spec.license       = 'Apache-2.0'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.engineering.redhat.com'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  # Depend on the same version of patternfly-sass
  spec.add_runtime_dependency 'patternfly-sass', "~> #{RCUE::VERSION}"

  # Converter's dependencies
  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'term-ansicolor'
  spec.add_development_dependency 'rugged', '~> 0.23.2'

  # Testing dependencies
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'nokogiri', '~> 1.6'
  spec.add_development_dependency 'rmagick', '~> 2.15'
  spec.add_development_dependency 'imgur-api', '~> 0.0.4'
  spec.add_development_dependency 'selenium-webdriver', '~> 2.46'

  spec.files      = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files = `git ls-files -- spec/*`.split("\n")
end
