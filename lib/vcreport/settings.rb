# frozen_string_literal: true

module VCReport
  RESULTS_DIR = 'results'
  REPORT_DIR = 'reports'
  DEFAULT_METRICS_NUM_THREADS = 1

  module Daemon
    DEFAULT_METRICS_INTERVAL = 3_600 # in seconds
  end

  module Report
    DEFAULT_NUM_SAMPLES_PER_PAGE = 50
  end
end
