# frozen_string_literal: true

require 'open-uri'
require 'tempfile'

module PrawnHtml
  module Tags
    class Img < Tag
      ELEMENTS = [:img].freeze

      def block?
        true
      end

      def custom_render(pdf, context)
        parsed_styles = Attributes.parse_styles(attrs.style)
        block_styles = context.block_styles
        evaluated_styles = adjust_styles(pdf, block_styles.merge(parsed_styles))

        src = @attrs.src
        if remote_url?(src)
          begin
            # Download the image to a temporary file
            temp_file = download_image(src)
            pdf.image(temp_file.path, evaluated_styles)
          rescue StandardError => e
            # If download fails, try to use the src directly
            # This will likely fail if the URL is not accessible, but it's worth a try
            pdf.image(src, evaluated_styles)
          end
        else
          # Local file path
          pdf.image(src, evaluated_styles)
        end
      end

      private

      def remote_url?(src)
        src.to_s.start_with?('http://', 'https://')
      end

      def download_image(url)
        temp_file = Tempfile.new(['prawn_html_img', File.extname(url)])
        temp_file.binmode

        # Download the image
        URI.open(url, 'rb') do |io|
          temp_file.write(io.read)
        end

        temp_file.rewind
        temp_file
      end

      def adjust_styles(pdf, img_styles)
        {}.tap do |result|
          w, h = img_styles['width'], img_styles['height']
          result[:width] = Utils.convert_size(w, options: pdf.page_width) if w
          result[:height] = Utils.convert_size(h, options: pdf.page_height) if h
          result[:position] = img_styles[:align] if %i[left center right].include?(img_styles[:align])
        end
      end
    end
  end
end
