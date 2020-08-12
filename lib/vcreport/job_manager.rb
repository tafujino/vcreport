# frozen_string_literal: true

require 'vcreport/settings'
require 'concurrent-ruby'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'
require 'posix/spawn'
require 'thor'
require 'English'
require 'mono_logger'

module VCReport
  class JobManager
    include Thor::Shell

    # @return [Integer]
    attr_reader :num_threads

    # @param num_threads [Integer]
    # @param logger      [MonoLogger, nil]
    # @param srun        [Boolean]
    def initialize(num_threads, logger, srun: false)
      @num_threads = num_threads
      @pool = Concurrent::FixedThreadPool.new(num_threads)
      @job_status = {} # Hash{ String => Concurrent::Promises::Future }
      @logger = logger
      @use_srun = srun
    end

    # @param result_paths [Array<String, Pathname>]
    def post(*result_paths)
      result_paths.map! { |path| File.expand_path(path).to_s }
      return unless should_run(result_paths)

      main_result_path = result_paths.first
      @job_status[main_result_path] =
        Concurrent::Promises.future_on(@pool, result_paths) do |result_paths|
        main_result_path = result_paths.first
        say_status 'start', main_result_path, :blue
        @logger&.info("Started a job for #{main_result_path}")
        begin
          is_success = yield
        rescue => e
          @logger&.error e.message
        end
        is_success = false if is_success && not_exist_results(result_paths)
        if is_success
          say_status 'create', main_result_path, :green
          @logger&.info("Created #{main_result_path}")
        else
          say_status 'fail', main_result_path, :red
          @logger&.error("Failed to create #{main_result_path}")
        end
        is_success
      end
    end

    def terminate
      @pool.shutdown
      @pool.wait_for_termination
    end

    private

    # @param result_paths [String]
    # @return             [Boolean]
    def not_exist_results(result_paths)
      nonexistent_paths = result_paths.reject { |path| File.exist?(path) }
      return false if nonexistent_paths.empty?

      @logger&.error 'Job successfully completed, but the following file(s) not found:'
      nonexistent_paths.each do |nonexistent_path|
        @logger.error nonexistent_path
      end
      true
    end

    # @param result_paths [Array<String>]
    # @return             [Boolean]
    def should_run(result_paths)
      main_result_path = result_paths.first
      if result_paths.all? { |path| File.exist?(path) }
        say_status 'skip', main_result_path, :yellow
        return false
      end
      unless @job_status.key?(main_result_path)
        say_status 'queue', main_result_path, :green
        return true
      end
      future = @job_status[main_result_path]
      unless future.resolved?
        say_status 'working', main_result_path, :yellow
        return false
      end
      if @job_status.value!
        @logger&.error <<~MESSAGE.squish
          File does not exist but job status is 'success'.
          Something went wrong: #{result_path}
        MESSAGE
        say_status 'queue', main_result_path, :green
      else
        say_status 'requeue', main_result_path, :yellow
      end
      true
    end

    # @param command [String]
    # @param dry_run [Boolean]
    # @return        [Boolean] true iff the command succeeded
    def shell(command, dry_run: false)
      return true if dry_run

      command = "srun #{command}" if @use_srun
      pid = POSIX::Spawn.spawn(command)
      Process.waitpid(pid)
      $CHILD_STATUS.success?
    end
  end
end
