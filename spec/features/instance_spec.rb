# frozen_string_literal: true

RSpec.describe 'Instance' do
  it 'preserves the styles in the instance' do
    pdf = Prawn::Document.new(page_size: 'A4')
    phtml = PrawnHtml::Instance.new(pdf)
    css = <<~CSS
      h1 { color: green }
      i { color: red }
    CSS
    phtml.append(css: css)
    phtml.append(html: '<h1>Some <i>HTML</i> before</h1>')
    pdf.text 'Some Prawn text'
    phtml.append(html: '<h1>Some <i>HTML</i> after</h1>')

    output_file = File.expand_path('../../examples/instance.pdf', __dir__)
    pdf.render_file(output_file) unless File.exist?(output_file)

    # Instead of comparing CRC32 checksums, which are sensitive to dictionary key order,
    # let's use PDF::Inspector to compare the text content of the PDFs
    require 'pdf/inspector'

    expected_pdf = File.read(output_file)
    rendered_pdf = pdf.render

    # Extract text from both PDFs
    expected_text = PDF::Inspector::Text.analyze(expected_pdf).strings.join
    actual_text = PDF::Inspector::Text.analyze(rendered_pdf).strings.join

    # Compare the text content
    expect(actual_text).to eq expected_text
  end
end
