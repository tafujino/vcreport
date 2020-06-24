# frozen_string_literal: true

module VCReport
  RESULTS_DIR = 'results'
  REPORT_DIR = 'reports'
  METRICS_NUM_THREADS = 8

  module Daemon
    DEFAULT_METRICS_INTERVAL = 3_600 # in second
    POLLING_INTERVAL = 60 # in second
  end
end
