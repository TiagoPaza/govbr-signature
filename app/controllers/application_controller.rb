require 'hexapdf'
require 'openssl'

include HexaPDF::Layout

class ApplicationController < ActionController::API
  def prepare_file
    pdf_doc = HexaPDF::Document.new

    page = pdf_doc.pages.add
    page_box = page.box

    frame = Frame.new(page_box.left + 20, page_box.bottom + 20,
                      page_box.width - 40, page_box.height - 40)

    boxes = []

    boxes << Box.create(width: 50, height: 50, margin: 20,
                        position: :float, align: :right,
                        background_color: "hp-blue-light2",
                        border: {width: 1, color: "hp-blue-dark"})
    boxes << pdf_doc.layout.lorem_ipsum_box(count: 3, position: :flow, text_align: :justify)

    i = 0
    frame_filled = false
    until frame_filled
      box = boxes[i]
      drawn = false
      until drawn || frame_filled
        result = frame.fit(box)
        if result.success?
          frame.draw(page.canvas, result)
          drawn = true
        else
          frame_filled = !frame.find_next_region
        end
      end
      i = (i + 1) % boxes.length
    end

    data = nil # Used for storing the to-be-signed data
    signing_mechanism = lambda do |io, byte_range|
      # Store the to-be-signed data in the local variable data
      io.pos = byte_range[0]
      data = io.read(byte_range[1])
      io.pos = byte_range[2]
      data << io.read(byte_range[3])
      ""
    end

    sig_field = pdf_doc.acro_form(create: true).create_signature_field('signature')

    widget = sig_field.create_widget(pdf_doc.pages[0], Rect: [20, 20, 120, 120])
    widget.create_appearance.canvas.
      stroke_color("red").rectangle(1, 1, 99, 99).stroke.
      font("Helvetica", size: 10).
      text("Certified by signer", at: [10, 10])

    pdf_doc.sign("signed.pdf", external_signing: signing_mechanism, doc_mdp_permissions: :form_filling, signature_size: 4_096 )

    sha256 = OpenSSL::Digest.new('SHA256')
    digest = sha256.digest(data)

    puts "data: #{data.bytes}"
    puts "Digest: #{digest}"

    base64 = Base64.encode64(digest)

    render json: { message: "PDF prepared successfully", bytes: data.bytes}, status: :ok
  end

  def sign_file
    p7s_file = params[:p7s]

    if p7s_file.respond_to?(:tempfile)
      pkcs = OpenSSL::PKCS7.new(File.read(p7s_file.tempfile))

      HexaPDF::DigitalSignature::Signing.embed_signature(File.open("signed.pdf", 'rb+'), pkcs.to_der)
    end

    render json: { message: "PDF signed successfully" }, status: :ok
  end

  def sign_file_bckp
    pdf_filename = params[:pdf].original_filename
    pdf_filename = pdf_filename.split('.').first

    pdf_file = params[:pdf]
    p7s_file = params[:p7s]

    if pdf_file.respond_to?(:tempfile) && p7s_file.respond_to?(:tempfile)
      pdf_doc = HexaPDF::Document.open(pdf_file.tempfile)

      pkcs = OpenSSL::PKCS7.new(File.read(p7s_file.tempfile))

      signing_proc = lambda do |io, byte_range|
        io.pos = byte_range[0]
        data = io.read(byte_range[1])

        io.pos = byte_range[2]
        data << io.read(byte_range[3])

        pkcs.to_der
      end
    end

    sig_field = pdf_doc.acro_form(create: true).create_signature_field('signature')

    widget = sig_field.create_widget(pdf_doc.pages[1], Rect: [500, 150, 400, 200])
    widget.create_appearance.canvas.stroke_color("red").rectangle(1, 1, 150, 45).stroke.
        font("Helvetica", size: 10).
        text("Certified by signer", at: [10, 10])

      # HexaPDF::Dictionary::with_options(signature: { ByteRange: [0, 0, 0, 0] }) do |options|
      #   pdf_doc.add_signature(sig_field, pkcs, options)
      #
      # end

      pdf_doc.sign(pdf_filename + "_assinado.pdf", signature_size: 10_000, external_signing: signing_proc, doc_mdp_permissions: :form_filling)

      # Embed the signature
      # HexaPDF::DigitalSignature::Signing.embed_signature(File.open(pdf_filename + "_assinado.pdf", 'rb+'), pkcs.to_der)

      render json: { message: "PDF signed successfully" }, status: :ok
  end

  def pdf_generator_worker
    PdfGeneratorJob.perform_async
    render json: {message: 'O PDF será gerado em breve.'}
  end

  def pdf_process_worker
    PdfProcessJob.perform_at(1.minute.from_now)
    render json: {message: 'Os arquivos PDFs será processado em breve.'}
  end



end
