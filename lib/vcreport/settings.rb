# frozen_string_literal: true

module VCReport
  SYSTEM_DIR = 'vcreport'
  METRICS_LOG_FILENAME = "#{SYSTEM_DIR}/metrics.log"
  MONITOR_LOG_FILENAME = "#{SYSTEM_DIR}/monitor.log"
  MONITOR_PROCESS_INFO_PATH = "#{SYSTEM_DIR}/.psinfo.yaml"
  RESULTS_DIR = 'results'
  REPORT_DIR = 'reports'
  CWLTOOL_PATH = 'cwltool'
  SINGULARITY_PATH = 'singularity'
  HUMAN_RESEQ_DIR = 'lib/human-reseq'
  C3_JS_PATH = 'lib/c3/c3.js'
  C3_CSS_PATH = 'lib/c3/c3.css'
  CONFIG_FILENAME = 'vcreport.yaml'
  MAX_SAMPLES = 100_000
  IGNORE_DEPS_INEXISTENCE = true # debug
  JOB_DEAULT_NUM_THREADS = 1

  module Monitor
    DEFAULT_INTERVAL = 3_600 # in seconds
  end

  module Report
    DEFAULT_NUM_SAMPLES_PER_PAGE = 50
    TOC_NESTING_LEVEL = 4
    WRAP_LENGTH = 100
  end

  module WebServer
    DEFAULT_PORT = 10_000
  end
end
