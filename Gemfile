source 'https://rubygems.org'

if ENV['CI']
  ruby RUBY_VERSION
else
  # TODO: read from the gemspec somehow? (Apparently Bundler will do that in Bundler 2.x)
  ruby IO.read('.ruby-version') rescue RUBY_VERSION
end

gemspec
