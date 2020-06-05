# frozen_string_literal: true

require 'vcreport/vcf_report'

module VCReport
  class SampleReport
    # @return [String] sample name
    attr_reader :name

    # @return [Array<VCFReport>]
    attr_accessor :vcf_reports

    def initialize(name)
      @name = name
      @vcf_reports = []
    end
  end
end
