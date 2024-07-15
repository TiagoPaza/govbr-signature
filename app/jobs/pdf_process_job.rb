class PdfProcessJob
  include Sidekiq::Job

  def perform(*args)
    path = Rails.root.join('public', 'queue')

    pdfs = Dir.glob(path.join("*.pdf")) # get all pdf file paths in the directory
    num_pdfs = pdfs.length # count the number of pdf files
    puts "Existem #{num_pdfs} arquivos PDF."

    items = pdfs.take(5) # get the first 5 pdf files

    items.each do |file|
      File.delete(file)
    end

    puts "5 arquivos PDF deletados."
  end
end
