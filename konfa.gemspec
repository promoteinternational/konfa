Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.3'
  s.name        = 'konfa'
  s.version     = '0.4.4'
  s.date        = '2018-06-07'
  s.summary     = "Application configuration"
  s.description = "Helps you avoid common pitfalls when dealing with app config"
  s.authors     = ["Gunnar Hansson", "Promote International"]
  s.email       = 'code@promoteint.com'
  s.files       = Dir.glob("lib/**/*.rb")
  s.homepage    = 'http://github.com/promoteinternational/konfa'
  s.license     = 'MIT'

  s.add_dependency "method_source", "~> 0.8"
  s.add_development_dependency "bundler", "~> 1.13"
  s.add_development_dependency "rake", "~> 12.0"
  s.add_development_dependency "rspec", "~> 3.6"
  s.add_development_dependency "ruby_dep", "~> 1.3.1"
end
