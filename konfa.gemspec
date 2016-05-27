Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.3'
  s.name        = 'konfa'
  s.version     = '0.4.2'
  s.date        = '2014-01-12'
  s.summary     = "Application configuration"
  s.description = "Helps you avoid common pitfalls when dealing with app config"
  s.authors     = ["Gunnar Hansson", "Avidity"]
  s.email       = 'code@avidiy.se'
  s.files       = Dir.glob("lib/**/*.rb")
  s.homepage    = 'http://github.com/avidity/konfa'
  s.license     = 'MIT'
end
