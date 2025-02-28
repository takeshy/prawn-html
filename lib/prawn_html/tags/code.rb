# frozen_string_literal: true

module PrawnHtml
  module Tags
    class Code < Tag
      ELEMENTS = [:code].freeze

      def tag_styles
        # Use a monospace style but don't force Courier font
        # This allows the code tag to inherit the font from the parent context
        # which should be 'noto-serif' that supports Japanese characters
        'white-space: pre'
      end
    end
  end
end
