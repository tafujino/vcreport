# VCReport

VCReport is a tool for generating reports on files used in genomic variant call such as VCF and CRAM.

The tool is able to monitor a directory where the variant calling of multiple samples is in progress. The report on the progress is generated and updated periodically. For each sample, several metrics are calculated and the results are listed on a single page.

The tool also provides a dashboard feature. The value of a metrics for monitoring (such as coverage) across samples is plotted in a chart to help detect an anormaly.

## Installation

VCReport is provided as a Ruby gem. Since the gem is not registered in RubyGems currently, it should be built and installed locally.

```
$ git clone https://github.com/tafujino/vcreport.git
$ git submodule update
$ cd vcreport
$ bundle install
$ rake build
$ gem install --local pkg/*.gem
```

Singularity image is also defined (`Singlarity/vcreport.def`).

## Usage

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/vcreport. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/vcreport/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Vcreport project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vcreport/blob/master/CODE_OF_CONDUCT.md).
