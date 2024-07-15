class PdfGeneratorJob
  include Sidekiq::Job

  def perform(*args)
    filename = SecureRandom.hex
    Dir.mkdir(Rails.root.join('public', 'queue')) unless File.exist?(Rails.root.join('public', 'queue'))
    Prawn::Document.generate(Rails.root.join('public', 'queue', "#{filename}.pdf")) do |pdf|
      pdf.text "Some text"
    end

    puts "PDF gerado com sucesso: #{filename}.pdf"
  end
end
