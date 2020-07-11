# frozen_string_literal: true

module VCReport
  RESULTS_DIR = 'results'
  REPORT_DIR = 'reports'
  CONFIG_FILENAME = 'vcreport.yaml'
  MAX_SAMPLES = 100_000
  HUMAN_RESEQ_DIR = 'lib/human-reseq'
  TOC_NESTING_LEVEL = 4
  IGNORE_DEPS_INEXISTENCE = true # debug
  JOB_DEAULT_NUM_THREADS = 1

  module Daemon
    DEFAULT_INTERVAL = 3_600 # in seconds
  end

  module Report
    DEFAULT_NUM_SAMPLES_PER_PAGE = 50
    WRAP_LENGTH = 100
  end
end
