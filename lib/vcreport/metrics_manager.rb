# frozen_string_literal: true

require 'vcreport/settings'
require 'concurrent-ruby'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'
require 'open3'
require 'thor'

module VCReport
  class MetricsManager
    include Thor::Shell

    # @return [Integer]
    attr_reader :num_threads

    # @return [Boolean]
    attr_reader :should_terminate

    # @param num_threads [Integer]
    def initialize(num_threads = DEFAULT_METRICS_NUM_THREADS)
      @num_threads = num_threads
      @pool = Concurrent::FixedThreadPool.new(num_threads)
      # Hash{ String => Symbol }
      # The value may be :success, :fail, :unfinished
      @job_status = {}
    end

    # @param result_path [String, Pathname]
    def post(result_path)
      result_path = result_path.to_s
      if File.exist?(result_path)
        say_status 'skip', result_path, :yellow
        return
      end
      case @job_status[result_path]
      when :success
        warn <<~MESSAGE.squish
          File does not exist but job status is 'success'.
          Something went wrong: #{result_path}
        MESSAGE
      when :unfinished
        # the job is already in queue
        say_status 'queued', result_path, :yellow
        return
      when :fail
        warn "Restart metrics calculation: #{result_path}"
      end
      # when status is :fail or nil
      @job_status[result_path] = :unfinished
      @job_status[result_path] = @pool.post do
        say_status 'start', result_path, :blue
        is_success = yield
        if is_success
          say_status 'create', result_path, :green
          :success
        else
          say_status 'fail', result_path, :red
          :fail
        end
      end
    end

    def wait
      @pool.shutdown
      @pool.wait_for_termination
    end

    class << self
      # @param command [String]
      # @return        [Boolean] true iff the command succeeded
      def shell(command)
        value = nil
        Open3.popen3(command) do |_, o, e, w|
          o.each { |s| puts s }
          e.each { |s| warn s }
          value = w.value
        end
        value.success?
      end
    end
  end
end
