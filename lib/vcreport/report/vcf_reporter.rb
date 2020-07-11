# frozen_string_literal: true

require 'vcreport/job_manager'
require 'vcreport/report/reporter'
require 'vcreport/chr_region'
require 'pathname'

module VCReport
  module Report
    class VcfReporter < Reporter
      BCFTOOLS_IMAGE_URI = 'docker://biocontainers/bcftools:v1.9-1-deb_cv1'

      # @param vcf_path        [Pathname]
      # @param chr_region      [ChrRegion]
      # @param metrics_dir     [Pathname]
      # @param job_manager [JobManager, nil]
      # @return                [Vcf, nil]
      def initialize(vcf_path, chr_region, metrics_dir, job_manager)
        @vcf_path = vcf_path
        @chr_region = chr_region
        @metrics_dir = metrics_dir
        @bcftools_stats_path =
          @metrics_dir / 'bcftools-stats' / "#{@vcf_path.basename}.bcftools-stats"
        super(job_manager, targets: @bcftools_stats_path, deps: @vcf_path)
      end

      # @return [Vcf]
      def parse
        lines = File.readlines(@bcftools_stats_path, chomp: true)
        field = lines.filter_map do |line|
          line.split("\t") unless line =~ /^#/
        end.group_by(&:first)
        sn = field['SN'].map.to_h { |_, _, k, v| [k, v.to_i] }
        num_snps = sn['number of SNPs:']
        num_indels = sn['number of indels:']
        ts_tv_ratio = field['TSTV'].first[4].to_f
        Vcf.new(
          @vcf_path,
          @bcftools_stats_path,
          @chr_region,
          num_snps,
          num_indels,
          ts_tv_ratio
        )
      end

      # @return [Boolean]
      def run_metrics
        container_data_dir = '/data'
        vcf_path = @vcf_path.symlink? ? @vcf_path.readlink : @vcf_path
        out_dir = File.dirname(@bcftools_stats_path)
        FileUtils.mkpath out_dir unless File.exist?(out_dir)
        tmp_path = "#{@bcftools_stats_path}.tmp"
        cmd = <<~COMMAND.squish
          singularity exec
          --bind #{vcf_path.dirname}:#{container_data_dir}
          #{BCFTOOLS_IMAGE_URI}
          bcftools stats
          #{container_data_dir}/#{vcf_path.basename}
          > #{tmp_path}
          2> #{@bcftools_stats_path}.log
        COMMAND
        is_success = JobManager.shell(cmd)
        FileUtils.mv(tmp_path, @bcftools_stats_path) if is_success
        is_success
      end
    end
  end
end
