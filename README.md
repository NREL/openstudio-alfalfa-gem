# Openstudio Metadata Gem

This gem produces semantic data representations for OpenStudio models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-metadata'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'openstudio-metadata'
	
## Usage

Find documentation at https://rubydoc.info/github/NREL/openstudio-metadata-gem/

## Note

This Gem requires OpenStudio@3.0 or greater

# Developing

## Environment Setup

- Prereqs: 
[bundle](https://bundler.io/), [OpenStudio](https://www.openstudio.net/), [ruby](https://www.ruby-lang.org/), [rbenv](https://github.com/rbenv/rbenv) (not technically required, but it will greately reduce headaches)

1. Install ruby with `rbenv`
  `$ rbenv install 2.5.5` 
  check [compatability matrix](https://github.com/NREL/OpenStudio/wiki/OpenStudio-SDK-Version-Compatibility-Matrix) for which ruby version is supported by your version of OpenStudio
2. Set project project to use specific ruby version
   `$ rbenv local 2.5.5` 
3. Install required gems with `bundle`
   `$ bundle install`

## Contributing
- Create branch
- Work on feature, add tests
- Make sure tests are passing: `bundle exec rspec`
- Add commits
- Run `bundle exec rake rubocop:auto_correct`
- Commit and push
- Add PR to feature 

## Releasing

* Update change log
* Update version in `/lib/openstudio/openstudio-metadata/version.rb`
* Merge down to master
* Release via github
* run `rake release` from master

## TODO

- [ ] Remove measures from OpenStudio-Measures to standardize on this location
- [ ] Update measures to code standards
- [ ] Review and fill out the gemspec file with author and gem description
