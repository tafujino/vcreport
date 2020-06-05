# frozen_string_literal: true

require 'vcreport/sample_report'
require 'pathname'

module VCReport
  class ProgressReport
    # @return [Pathname]
    attr_reader :directory

    # @return [Array<SampleReport>]
    attr_reader sample_reports

    def initialize(directory, sample_reports)
      @directory = directory
      @sample_reports = sample_reports
    end
  end
end
