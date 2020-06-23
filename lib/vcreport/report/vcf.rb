# frozen_string_literal: true

require 'fileutils'
require 'rake'
require 'vcreport/metrics_manager'

module VCReport
  module Report
    class Vcf
      BCFTOOLS_IMAGE_URI = 'docker://biocontainers/bcftools:v1.9-1-deb_cv1'

      extend Rake::DSL

      # @return [String]
      attr_reader :chr_region

      # @return [Integer, nil]
      attr_reader :num_snps

      # @return [Integer, nil]
      attr_reader :num_indels

      # @return [Float, nil]
      attr_reader :ts_tv_ratio

      def initialize(chr_region, num_snps = nil, num_indels = nil, ts_tv_ratio = nil)
        @chr_region = chr_region
        @num_snps = num_snps
        @num_indels = num_indels
        @ts_tv_ratio = ts_tv_ratio
      end

      class << self
        # @param vcf_path    [Pathname]
        # @param chr_region  [String]
        # @param metrics_dir [Pathname]
        # @param metrics_dir [MetricsManager]
        # @return            [Report::Vcf, nil]
        def run(vcf_path, chr_region, metrics_dir, metrics_manager)
          bcftools_stats_path =
            metrics_dir / 'bcftools_stats_path' / "#{vcf_path.basename}.bcftools-stats"
          if bcftools_stats_path.exist?
            load_bcftools_stats(chr_region, bcftools_stats_path)
          else
            metrics_manager.post(vcf_path) do
              run_bcftools_stats(vcf_path, bcftools_stats_path)
            end
            Report::Vcf.new(chr_region)
          end
        end

        private

        # @param chr_region          [String]
        # @param bcftools_stats_path [Pathname]
        # @return                    [Report::Vcf]
        def load_bcftools_stats(chr_region, bcftools_stats_path)
          field = File.readlines(bcftools_stats_path, chomp: true).reject do |line|
            line =~ /^#/
          end.map do |line|
            line.split("\t")
          end.group_by(&:first)
          sn = field['SN'].map.to_h { |_, _, k, v| [k, v.to_i] }
          num_snps = sn['number of SNPs:']
          num_indels = sn['number of indels:']
          ts_tv_ratio = field['TSTV'].first[4].to_f
          Report::Vcf.new(chr_region, num_snps, num_indels, ts_tv_ratio)
        end

        # @param vcf_path            [Pathname]
        # @param bcftools_stats_path [Pathname]
        # @return                    [Boolean]
        def run_bcftools_stats(vcf_path, bcftools_stats_path)
          container_data_dir = '/data'
          vcf_path = vcf_path.readlink if vcf_path.symlink?
          tmp_path = "#{bcftools_stats_path}.tmp"
          is_success = MetricsManager.shell <<~COMMAND.squish
            singularity exec
            --bind #{vcf_path.dirname}:#{container_data_dir}
            #{BCFTOOLS_IMAGE_URI}
            bcftools stats
            #{container_data_dir}/#{vcf_path.basename}
            > #{tmp_path}
            2> #{bcftools_stats_path}.log
          COMMAND
          mv tmp_path, bcftools_stats_path if is_success
          is_success
        end
      end
    end
  end
end
