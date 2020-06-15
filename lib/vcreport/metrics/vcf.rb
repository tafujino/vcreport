# frozen_string_literal: true

require 'pathname'
require 'rake'

module VCReport
  module Metrics
    class Vcf
      extend Rake::DSL

      BCFTOOLS_IMAGE_URI = 'docker://biocontainers/bcftools:v1.9-1-deb_cv1'

      # @return [Pathname]
      attr_reader :vcf_path

      # @return [Pathname]
      attr_reader :bcftools_stats_path

      # @param vcf_path    [String]
      # @param metrics_dir [String]
      def initialize(vcf_path, metrics_dir)
        @vcf_path = Pathname.new(vcf_path)
        @metrics_dir = Pathname.new(metrics_dir)
        @bcftools_stats_path =
          @metrics_dir / 'bcftools_stats_path' / "#{vcf_path.basename}.bcftools-stats"
      end

      def run_bcftools_stats
        container_data_dir = '/data'
        vcf_path = @vcf_path.readlink if vcf_path.symlink?
        tmp_path = "#{@bcftools_stats_path}.tmp"
        sh <<~COMMAND.squish
          singularity exec
          --bind #{vcf_path.dirname}:#{container_data_dir}
          #{BCFTOOLS_IMAGE_URI}
          bcftools stats
          #{container_data_dir}/#{vcf_path.basename}
          > #{tmp_path}
          2> #{@bcftools_stats_path}.log
        COMMAND
        mv tmp_path, @bcftools_stats_path
      end
    end
  end
end
