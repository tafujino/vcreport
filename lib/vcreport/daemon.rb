# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/sample_report'
require 'vcreport/chr_regions'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'

module VCReport
  module Daemon
    class << self
      # @param data_dir [String]
      # @param report_dir [String]
      def run(data_dir, report_dir)
        data_dir = Pathname.new(data_dir)
        report_dir = Pathname.new(report_dir)
        loop do
          reports = scan_samples(data_dir).map do |sample_dir|
            report = sample_report(sample_dir)
            report.generate_html(report_dir)
            report
          end
          ProgressReport.new(reports).generate_html(report_dir)
          sleep INTERVAL
        end
      end

      private

      # @param data_dir [Pathname]
      # @return         [Array<Pathname>]
      def scan_samples(data_dir)
        Dir[data_dir / '*']
          .map { |e| Pathname.new(e) }
          .select(&:directory?)
      end

      # @param sample_dir [Pathname]
      # @return           [SampleReport]
      def sample_report(sample_dir)
        name = sample_dir.basename.to_s
        warn "sample: #{name}"
        warn "directory: #{sample_dir}"

        report = SampleReport.new(name)
        return report unless (sample_dir / 'finish').exist?

        metrics_dir = sample_dir / 'metrics'
        CHR_REGIONS.each do |chr_region|
          # VCF is supposed to be gzipped
          vcf_path = "#{name}.#{chr_region}.g.vcf.gz"
          report.vcf_report[chr_region] = vcf_report(vcf_path, metrics_dir)
        end
        report
      end

      # @param vcf_path    [Pathname]
      # @param metrics_dir [Pathname]
      # @return            [VcfReport]
      def vcf_report(vcf_path)
        bcftools_stats_dir = metrics_dir / 'bcftoosl-stats'
        FileUitls.mkpath bcftools_stats_dir unless bcftools_stats_dir.exist?
        vcf_basename = vcf_path.basename
        bcftools_stats_path = bcftools_stats_dir / "#{vcf_basename}.bcftools-stats"
        container_data_dir = '/data'
        ret = system <<~COMMAND.squish
          singularity exec
          --bind #{vcf_path.dirname}:#{container_data_dir}
          docker://biocontainers/bcftools:v1.9-1-deb_cv1
          bcftools stats
          #{container_data_dir}/#{vcf_basename}
          > #{bcftools_stats_path}
          2> #{bcftools_stats_path}.log
        COMMAND
        warn 'bcftools failed' unless ret

        VcfReport.load_bcftools_stats(bcftools_stats_path)
      end
    end
  end
end
