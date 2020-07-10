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
        # @param prefix            [String]
        # @param out_dir           [Pathname]
        # @param context           [Binding, nil]
        # @param paging            [Paging, nil]
        # @param overwrite         [Boolean]
        # @param render_toc        [Boolean]
        # @param toc_nesting_level [Integer, nil]
        def run(
              prefix,
              out_dir,
              context = nil,
              paging: nil,
              overwrite: true,
              render_toc: false,
              toc_nesting_level: nil
            )
          render_markdown(prefix, out_dir, context, paging: paging, overwrite: overwrite)
          render_html(
            prefix,
            out_dir,
            context,
            paging: paging,
            overwrite: overwrite,
            render_toc: render_toc,
            toc_nesting_level: toc_nesting_level
          )
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

        # @param prefix            [String]
        # @param out_dir           [Pathname]
        # @param context           [Binding, nil]
        # @param paging            [Paging, nil]
        # @param overwrite         [Boolean]
        # @param render_toc        [Boolean]
        # @param toc_nesting_level [Integer, nil]
        def render_html(
              prefix,
              out_dir,
              context = nil,
              paging: nil,
              overwrite: true,
              render_toc: false,
              toc_nesting_level: nil
            )
          filename = "#{prefix}#{paging&.digits}"
          markdown_path = out_dir / "#{filename}.md"
          html_path = out_dir / "#{filename}.html"
          return if skip?(html_path, overwrite)

          context ||= binding
          markdown = Redcarpet::Markdown.new(
            Redcarpet::Render::HTML.new(with_toc_data: true),
            tables: true,
            fenced_code_blocks: true,
            disable_indented_code_blocks: false
          )
          markdown_text = File.read(markdown_path)
          template_path = "#{TEMPLATE_DIR}/#{prefix}.html.erb"
          context.local_variable_set(:content_body, markdown.render(markdown_text))
          if render_toc
            toc = Redcarpet::Markdown.new(
              Redcarpet::Render::HTML_TOC.new(nesting_level: toc_nesting_level)
            )
            context.local_variable_set(:toc_body, toc.render(markdown_text))
          end
          render_erb(template_path, html_path, context)
        end

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
