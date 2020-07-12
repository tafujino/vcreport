# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'vcreport/job_manager'
require 'vcreport/settings'

module VCReport
  module CWL
    class << self
      # @param path     [String, Pathmame]
      # @param absolute [Boolean]
      # @param edam     [Integer]
      # @return         [Hash{ Symbol => String }]
      def file_field(path, absolute: true, edam: nil)
        field = { class: 'File' }
        path = File.expand_path(path) if absolute
        field[:path] = path.to_s
        field[:format] = "#{EDAM_DOMAIN}/format_#{edam}" if edam
        field
      end

      # @return [Boolean]
      def run(script_path, job_definition, out_dir)
        job_path = out_dir / 'job.yaml'
        store_job_file(job_path, job_definition)
        JobManager.shell <<~COMMAND.squish
          #{CWLTOOL_PATH}
          --singularity
          --outdir #{out_dir}
          #{script_path}
          #{job_path}
          >& #{out_dir / 'cwl.log'}
        COMMAND
      end

      private

      def store_job_file(job_path, job_definition)
        File.write(job_path, YAML.dump(job_definition.deep_stringify_keys))
      end
    end
  end
end
