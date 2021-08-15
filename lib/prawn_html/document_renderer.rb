# frozen_string_literal: true

module PrawnHtml
  class DocumentRenderer
    NEW_LINE = { text: "\n" }.freeze
    SPACE = { text: ' ' }.freeze

    # Init the DocumentRenderer
    #
    # @param pdf [Prawn::Document] target Prawn PDF document
    def initialize(pdf)
      @buffer = []
      @context = Context.new
      @doc_styles = {}
      @pdf = pdf
    end

    # Assigns the document styles
    #
    # @param styles [Hash] styles hash with CSS selectors as keys and rules as values
    def assign_document_styles(styles)
      @doc_styles = styles.transform_values do |style_rules|
        Attributes.new(style: style_rules).styles
      end
    end

    # On tag close callback
    #
    # @param element [Tag] closing element wrapper
    def on_tag_close(element)
      render_if_needed(element)
      apply_tag_close_styles(element)
      context.last_text_node = false
      context.pop
    end

    # On tag open callback
    #
    # @param tag_name [String] the tag name of the opening element
    # @param attributes [Hash] an hash of the element attributes
    #
    # @return [Tag] the opening element wrapper
    def on_tag_open(tag_name, attributes)
      tag_class = Tag.class_for(tag_name)
      return unless tag_class

      tag_class.new(tag_name, attributes, doc_styles).tap do |element|
        setup_element(element)
      end
    end

    # On text node callback
    #
    # @param content [String] the text node content
    #
    # @return [NilClass] nil value (=> no element)
    def on_text_node(content)
      return if content.match?(/\A\s*\Z/)

      text = content.gsub(/\A\s*\n\s*|\s*\n\s*\Z/, '').delete("\n").squeeze(' ')
      buffer << context.text_node_styles.merge(text: ::Oga::HTML::Entities.decode(context.before_content) + text)
      context.last_text_node = true
      nil
    end

    # Render the buffer content to the PDF document
    def render
      return if buffer.empty?

      options = context.block_styles.slice(:align, :leading, :margin_left, :mode, :padding_left)
      output_content(buffer.dup, options)
      buffer.clear
      context.last_margin = 0
    end

    alias_method :flush, :render

    private

    attr_reader :buffer, :context, :doc_styles, :pdf

    def setup_element(element)
      add_space_if_needed unless render_if_needed(element)
      apply_tag_open_styles(element)
      context.push(element)
      element.custom_render(pdf, context) if element.respond_to?(:custom_render)
    end

    def add_space_if_needed
      buffer << SPACE if buffer.any? && !context.last_text_node && ![NEW_LINE, SPACE].include?(buffer.last)
    end

    def render_if_needed(element)
      render_needed = element&.block? && buffer.any? && buffer.last != NEW_LINE
      return false unless render_needed

      render
      true
    end

    def apply_tag_close_styles(element)
      tag_styles = element.tag_close_styles
      context.last_margin = tag_styles[:margin_bottom].to_f
      pdf.move_down(tag_styles[:padding_bottom]) if tag_styles.include?(:padding_bottom)
      pdf.move_down(context.last_margin) if context.last_margin > 0
    end

    def apply_tag_open_styles(element)
      tag_styles = element.tag_open_styles
      margin = (tag_styles[:margin_top].to_f - context.last_margin)
      pdf.move_down(margin) if margin > 0
      pdf.move_down(tag_styles[:padding_top]) if tag_styles.include?(:padding_top)
    end

    def output_content(buffer, options)
      buffer.each { |item| item[:callback] = item[:callback].new(pdf, item) if item[:callback] }
      if (left = options.delete(:margin_left).to_f + options.delete(:padding_left).to_f) > 0
        pdf.indent(left) { pdf.formatted_text(buffer, options) }
      else
        pdf.formatted_text(buffer, options)
      end
    end
  end
end
