# frozen_string_literal: true

require 'vcreport/settings'
require 'vcreport/report/paging'
require 'pathname'
require 'erb'
require 'redcarpet'
require 'thor'

module VCReport
  module Report
    module Render
      extend Thor::Shell

      TEMPLATE_DIR = 'template'

      class << self
        # @param prefix    [String]
        # @param out_dir   [Pathname]
        # @param context   [Binding, nil]
        # @param paging    [Paging, nil]
        # @param overwrite [Boolean]
        def run(prefix, out_dir, context = nil, paging: nil, overwrite: true)
          render_markdown(prefix, out_dir, context, paging: paging, overwrite: overwrite)
          render_html(prefix, out_dir, paging: paging, overwrite: overwrite)
        end

        private

        # @param prefix    [String]
        # @param out_dir   [Pathname]
        # @param context   [Binding, nil]
        # @param paging    [Paging, nil]
        # @param overwrite [Boolean]
        def render_markdown(prefix, out_dir, context = nil, paging: nil, overwrite: true)
          markdown_path = out_dir / "#{prefix}#{paging&.digits}.md"
          return if skip?(markdown_path, overwrite)

          context ||= binding
          %i[prev next].map do |m|
            context.local_variable_set(
              :"#{m}_html_path",
              paging&.send(m)&.digits&.then { |digits| "#{prefix}#{digits}.html" }
            )
          end
          template_path = "#{TEMPLATE_DIR}/#{prefix}.md.erb"
          render_erb(template_path, markdown_path, context)
        end

        # @param prefix    [String]
        # @param out_dir   [Pathname]
        # @param paging    [Paging, nil]
        # @param overwrite [Boolean]
        def render_html(prefix, out_dir, paging: nil, overwrite: true)
          filename = "#{prefix}#{paging&.digits}"
          markdown_path = out_dir / "#{filename}.md"
          html_path = out_dir / "#{filename}.html"
          return if skip?(html_path, overwrite)

          markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
          markdown_text = File.read(markdown_path)
          html_body = markdown.render(markdown_text)
          template_path = "#{TEMPLATE_DIR}/#{prefix}.html.erb"
          render_erb(template_path, html_path, binding)
        end

        private

        # @param path      [String]
        # @param overwrite [Boolean]
        def skip?(path, overwrite)
          if File.exist?(path) && !overwrite
            say_status 'skip', path, :yellow
            true
          else
            false
          end
        end

        # @param template_path [Pathname]
        # @param out_path      [Pathname]
        # @param context       [Binding, nil]
        def render_erb(template_path, out_path, context = nil)
          template_path = File.expand_path(template_path, __dir__)
          erb = ERB.new(File.open(template_path).read, trim_mode: '-')
          context ||= binding
          text = erb.result(context)
          File.write(out_path, text)
          say_status 'create', out_path, :green
        end
      end
    end
  end
end
