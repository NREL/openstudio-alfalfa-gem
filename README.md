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

Find documentation at https://www.rubydoc.info/gems/openstudio-metadata/0.0.1

## Note

This Gem requires OpenStudio@3.0 or greater

# Developing

## Environment Setup

- Prereqs: 
[bundle](https://bundler.io/), [OpenStudio](https://www.openstudio.net/), [ruby](https://www.ruby-lang.org/), [rbenv](https://github.com/rbenv/rbenv) (not technically required, but it will greately reduce headaches)

1. Install ruby with `rbenv`
	
        $ rbenv install 2.5.5

	check [compatability matrix](https://github.com/NREL/OpenStudio/wiki/OpenStudio-SDK-Version-Compatibility-Matrix) for which ruby version is supported by your version of OpenStudio
	
2. Set project project to use specific ruby version:

	    $ rbenv local 2.5.5

3. Install required gems with `bundle`
        
		$ bundle install

## Contributing
1. Create branch
2. Work on feature, add tests
3. Make sure tests are passing: `bundle exec rspec`
4. Add commits
5. Run `bundle exec rake rubocop:auto_correct`
6. Commit and push
7. Add PR to feature 

## Releasing

1. Update change log
2. Update version in `/lib/openstudio/openstudio-metadata/version.rb`
3. Run `bundle exec rake rubocop:auto_correct`
3. Merge develop down to master and confirm tests pass
4. Release via github
5. run `rake release` from master
