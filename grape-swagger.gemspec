# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "grape-swagger"
  s.version = "0.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Vandecasteele"]
  s.date = "2014-02-06"
  s.description = "A simple way to add proper auto generated documentation - that can be displayed with swagger - to your inline described grape API"
  s.email = "tim.vandecasteele@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.markdown"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "CHANGELOG.markdown",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.markdown",
    "Rakefile",
    "VERSION",
    "grape-swagger.gemspec",
    "lib/grape-swagger.rb",
    "spec/api_models_spec.rb",
    "spec/default_api_spec.rb",
    "spec/form_params_spec.rb",
    "spec/grape-swagger_helper_spec.rb",
    "spec/grape-swagger_spec.rb",
    "spec/hide_api_spec.rb",
    "spec/non_default_api_spec.rb",
    "spec/simple_mounted_api_spec.rb",
    "spec/spec_helper.rb",
    "test/config.ru",
    "test/nested_api.rb"
  ]
  s.homepage = "http://github.com/tim-vandecasteele/grape-swagger"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Add swagger compliant documentation to your grape API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<grape>, [">= 0.7.0"])
      s.add_runtime_dependency(%q<grape-entity>, [">= 0.4.2"])
      s.add_runtime_dependency(%q<kramdown>, [">= 1.3.1"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<grape>, [">= 0.7.0"])
      s.add_dependency(%q<grape-entity>, [">= 0.4.2"])
      s.add_dependency(%q<kramdown>, [">= 1.3.1"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<grape>, [">= 0.7.0"])
    s.add_dependency(%q<grape-entity>, [">= 0.4.2"])
    s.add_dependency(%q<kramdown>, [">= 1.3.1"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end

