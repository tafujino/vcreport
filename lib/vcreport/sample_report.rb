# frozen_string_literal: true

require 'vcreport/vcf_report'
require 'fileutils'
require 'pathname'
require 'erb'
require 'redcarpet'

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

    # @param report_dir [String]
    def render(report_dir)
      report_dir = Pathname.new(report_dir)
      css_path = report_dir / 'github-markdown.css'
      unless File.exist?(css_path)
        system "curl https://raw.githubusercontent.com/sindresorhus/github-markdown-css/gh-pages/github-markdown.css > #{css_path}"
      end
      out_dir = report_dir / @name
      FileUtils.mkpath out_dir
      markdown_template_path = File.expand_path('template/report.md.erb', __dir__)
      html_template_path = File.expand_path('template/report.html.erb', __dir__)
      markdown_path = out_dir / 'report.md'
      html_path = out_dir / 'report.html'
      sample_name = @name
      erb = ERB.new(File.open(markdown_template_path).read, nil, '-')
      markdown_text = erb.result(binding)
      File.write(markdown_path, markdown_text)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
      html_body = markdown.render(markdown_text)
      erb = ERB.new(File.open(html_template_path).read, nil, '-')
      File.write(html_path, erb.result(binding))
    end
  end
end
