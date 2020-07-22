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
  LIB_DIR = File.expand_path("#{__dir__}/..")
  HUMAN_RESEQ_DIR = "#{LIB_DIR}/human-reseq"
  D3_JS_PATH = "#{LIB_DIR}/d3/d3.v5.js"
  C3_JS_PATH = "#{LIB_DIR}/c3/c3.js"
  C3_CSS_PATH = "#{LIB_DIR}/c3/c3.css"
  GITHUB_MARKDOWN_CSS_PATH = "#{LIB_DIR}/github-markdown-css/github-markdown.css"
  CONFIG_FILENAME = 'vcreport.yaml'
  MAX_SAMPLES = 100_000
  IGNORE_DEPS_INEXISTENCE = true # debug
  JOB_DEAULT_NUM_THREADS = 1

  module Monitor
    DEFAULT_INTERVAL = 3_600 # in seconds
  end

  module Report
    DEFAULT_NUM_SAMPLES_PER_PAGE = 50
    SAMPLE_TOC_NESTING_LEVEL = 4
    DASHBOARD_TOC_NESTING_LEVEL = 3
    WRAP_LENGTH = 100
  end

  module WebServer
    DEFAULT_PORT = 10_000
  end
end
