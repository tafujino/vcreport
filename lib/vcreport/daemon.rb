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
            report.render(report_dir)
            report
          end
          ProgressReport.new(reports).render(report_dir)
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
          report.vcf_report[chr_region] = VcfReport.run(vcf_path, metrics_dir)
        end
        report
      end
    end
  end
end
