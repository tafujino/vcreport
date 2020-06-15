# frozen_string_literal: true

require 'pathname'
require 'erb'
require 'redcarpet'
require 'thor'

module VCReport
  module Report
    module Render
      include Thor::Shell

      TEMPLATE_DIR = 'template'

      # @param prefix           [String]
      # @param out_dir          [Pathname]
      # @param should_overwrite [Boolean]
      def render_markdown(prefix, out_dir, should_overwrite = true)
        markdown_path = out_dir / "#{prefix}.md"
        return if skip?(markdown_path, should_overwrite)

        template_path = "#{TEMPLATE_DIR}/#{prefix}.md.erb"
        render_erb(template_path, markdown_path, binding)
      end

      # @param prefix           [String]
      # @param out_dir          [Pathname]
      # @param should_overwrite [Boolean]
      def render_html(prefix, out_dir, should_overwrite = true)
        markdown_path = out_dir / "#{prefix}.md"
        html_path = out_dir / "#{prefix}.html"
        return if skip?(html_path, should_overwrite)

        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
        markdown_text = File.read(markdown_path)
        html_body = markdown.render(markdown_text)
        template_path = "#{TEMPLATE_DIR}/#{prefix}.html.erb"
        render_erb(template_path, html_path, binding)
      end

      private

      # @param path [String]
      # @param should_overwrite [Boolean]
      def skip?(path, should_overwrite)
        if File.exist?(path) && !should_overwrite
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
        erb = ERB.new(File.open(template_path).read, nil, '-')
        context ||= binding
        text = erb.result(context)
        File.write(out_path, text)
        say_status 'create', out_path, :green
      end
    end
  end
end
