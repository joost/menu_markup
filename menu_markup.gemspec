# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'menu_markup/version'

Gem::Specification.new do |spec|
  spec.name          = "menu_markup"
  spec.version       = MenuMarkup::VERSION
  spec.authors       = ["Joost Hietbrink"]
  spec.email         = ["joost@webuildinternet.com"]
  spec.license       = "MIT"

  spec.summary       = %q{Ruby gem to parce MenuMarkup.}
  spec.description   = %q{MenuMarkup is a super simple markup to specify menu data in plain text. When the MenuMarkup is parsed it creates a Menu. A Menu consists of two types: Items and Sections. Items have multiple Prices.}
  spec.homepage      = "http://www.webuildinternet.com/2012/07/04/menu-markup-specification/"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "treetop", '~> 1.4', ">= 1.4.15"
  spec.add_dependency "activesupport", '~> 4' # for #presence method
  spec.add_development_dependency "bundler", '~> 1.9'
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "rspec-collection_matchers", '~> 1.1', '>= 1.1.2'
  spec.add_development_dependency "guard", "~> 2.12"
  spec.add_development_dependency "guard-rspec", "~> 4.6"
end
