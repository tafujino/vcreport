# VCReport

VCReport is a tool for generating reports on files used in genomic variant call such as VCF and CRAM.

The tool is able to monitor a directory where the variant calling of multiple samples is in progress. The report on the progress is generated and updated periodically. For each sample, several metrics are calculated and the results are listed on a single page.

The tool also provides a dashboard feature. The values of a metrics for monitoring (such as coverage) across samples are plotted in a chart to help detect an anormaly.

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

Singularity image is also defined (`Singularity/vcreport.def`).

## Usage

### Directory structure and settings

In VCReport, variant call project is managed per directory. The project directory is supposed to have the following structure.

```
<project dir>
  +-- results/
    +-- <sample0>/
    +-- <sample1>/
    +-- <sample2>/
         ...
  +--- reports/
  +--- vcreport/
  +--- vcreport.yaml
```

Each sample data is placed in `results` directory by the user. VCReport creates `reports` directory, where report HTML files are generated. It also creates `vcreport` directory used for management and logging. The user has to describe `vcreport.yaml` needed to run VCReport properly.

The name of a sample directory should be identical to the sample name. If the name of the sample is `AAA`, the name of the directory is also `AAA`. The CRAM file used for variant call is supposed to be `AAA.dedup.cram`. There may be multiple VCF files calculated on given genomic intervals. If the interval name is `BBB`, the name of VCF file is supposed to be `AAA.BBB.g.vcf.gz`. In order to tell VCReport that CRAM and VCFs are already created, `finish` file should be put in a sample directory.

The structure of `vcreport.yaml` is like the following.

```
reference:
  desc: GRCh38
  path: /path/to/reference.fasta
vcf:
  regions:
    autosome:
      desc: autosomal region
    chrX:
      desc: chrX
    chrY:
      desc: chrY
metrics:
  picard-CollectWgsMetrics:
    interval-list:
      autosome:
        desc: autosome
        path: /path/to/autosome.interval_list
      chrX:
        desc: chrX
        path: /path/to/chrX.interval_list
      chrY:
        desc: chrY
        path: /path/to/chrY.interval_list
```

### Command line

For directory monitoring `vcreport monitor` command is used.

```
$ vcreport monitor start <project dir>
```

When `vcreport monitor start` is run, a monotoring daemon is launched. The daemon periodically (by default, per hour) generates reports on samples. If files on new samples are added to the project directory, metrics calculations are automatically performed.

To check the staus of the daemon, use `vcreport monitor status` command.

```
$ vcreport monitor status <project dir>
```

The daemon is terminated by the following command.

```
$ vcreport monitor stop <project dir>
```

Instead of periodical monitoring, one-time report generation and metrics calculation is also possible. For report file rendering, run

```
$ vcreport render <project dir>
```

and for metrics calculation, run

```
$ vcreport metrics <project dir>
```

VCReport also provides a simple web server.

```
$ vcreport http <project dir> -p <port number>
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tafujino/vcreport. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/vcreport/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the VCReport project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tafujino/vcreport/blob/master/CODE_OF_CONDUCT.md).
