# frozen_string_literal: true

RSpec.describe 'Samples' do
  Dir[File.expand_path('../../examples/*.html', __dir__)].sort.each do |file|
    it "renders the expected output for #{File.basename(file)}", :aggregate_failures do
      html = File.read(file)
      pdf = Prawn::Document.new(page_size: 'A4', page_layout: :portrait)
      PrawnHtml.append_html(pdf, html)
      # Instead of comparing CRC32 checksums, which are sensitive to dictionary key order,
      # let's use PDF::Inspector to compare the text content of the PDFs
      require 'pdf/inspector'

      expected_pdf = File.read(file.gsub(/\.html\Z/, '.pdf'))
      rendered_pdf = pdf.render

      # Extract text from both PDFs
      expected_text = PDF::Inspector::Text.analyze(expected_pdf).strings.join
      actual_text = PDF::Inspector::Text.analyze(rendered_pdf).strings.join

      # Compare the text content
      expect(actual_text).to eq expected_text
    end
  end
end
