# frozen_string_literal: true

require 'vcreport/job_manager'
require 'vcreport/report/reporter'
require 'vcreport/report/vcf'
require 'vcreport/report/vcf/bcftools_stats'
require 'vcreport/report/vcf/bcftools_stats_reporter'

module VCReport
  module Report
    class VcfReporter < Reporter
      def initialize(vcf_path, chr_region, metrics_dir, job_manager)
        @vcf_path = vcf_path
        @chr_region = chr_region
        @metrics_dir = metrics_dir
        @job_manager = job_manager
        super(@job_manager)
      end

      # @return [BcftoolsStats]
      def parse
        bcftools_stats = Vcf::BcftoolsStatsReporter.new(
          @vcf_path, @chr_region, @metrics_dir, @job_manager
        ).try_parse
        Vcf.new(@vcf_path, @chr_region, bcftools_stats)
      end
    end
  end
end
