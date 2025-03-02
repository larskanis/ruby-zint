module Zint
  RSpec.describe Barcode do
    let(:outfile) { File.join(Dir.tmpdir, "out.svg") }
    let(:buffer_outfile) { File.join(Dir.tmpdir, "buffer.png") }
    let(:input_file) { "spec/fixtures/input_file.txt" }

    let(:barcode) { described_class.new(value: "Test") }
    let(:barcode_with_input_file) { described_class.new(input_file: input_file) }

    describe "exports" do
      after do
        [outfile, buffer_outfile].each do |file|
          File.delete(file) if File.exist?(file)
        end
      end

      it "exports barcode to file from given value" do
        barcode.to_file(path: outfile)

        expect(File.exist?(outfile)).to be true
      end

      it "exports barcode to file from input file" do
        barcode_with_input_file.to_file(path: outfile)

        expect(File.exist?(outfile)).to be true
      end

      it "exports barcode to memory file from given value" do
        svg_file = barcode.to_memory_file(extension: ".svg")

        expect(svg_file.include?("<svg")).to be true
      end

      it "exports barcode to memory file from input file" do
        svg_file = barcode_with_input_file.to_memory_file(extension: ".svg")

        expect(svg_file.include?("<svg")).to be true
      end

      it "exports barcode to buffer from given value" do
        require "digest/md5"

        bitmap = barcode.to_buffer

        require "chunky_png"
        png = ChunkyPNG::Image.new(bitmap.width, bitmap.height, ChunkyPNG::Color::TRANSPARENT)
        white = ChunkyPNG::Color("white")
        black = ChunkyPNG::Color("black")

        bitmap.pixels.each do |pixel|
          png.compose_pixel(pixel.x, pixel.y, (pixel.colour == "K") ? black : white)
        end

        png.save(buffer_outfile)

        expect(Digest::MD5.file(buffer_outfile).hexdigest).to eq Digest::MD5.file("spec/fixtures/buffer.png").hexdigest
      end

      it "exports barcode to buffer from input file" do
        require "digest/md5"

        bitmap = barcode_with_input_file.to_buffer

        require "chunky_png"
        png = ChunkyPNG::Image.new(bitmap.width, bitmap.height, ChunkyPNG::Color::TRANSPARENT)
        white = ChunkyPNG::Color("white")
        black = ChunkyPNG::Color("black")

        bitmap.pixels.each do |pixel|
          png.compose_pixel(pixel.x, pixel.y, (pixel.colour == "K") ? black : white)
        end

        png.save(buffer_outfile)

        expect(Digest::MD5.file(buffer_outfile).hexdigest).to eq Digest::MD5.file("spec/fixtures/buffer_from_input_file.png").hexdigest
      end

      it "exports colored barcode to buffer from value" do
        require "digest/md5"

        bitmap = described_class.new(value: "Test", type: Zint::BARCODE_ULTRA).to_buffer

        require "chunky_png"
        png = ChunkyPNG::Image.new(bitmap.width, bitmap.height, ChunkyPNG::Color::TRANSPARENT)
        white = ChunkyPNG::Color("white")
        black = ChunkyPNG::Color("black")
        cyan = ChunkyPNG::Color("cyan")
        blue = ChunkyPNG::Color("blue")
        magenta = ChunkyPNG::Color("magenta")
        red = ChunkyPNG::Color("red")
        yellow = ChunkyPNG::Color("yellow")
        green = ChunkyPNG::Color("green")

        bitmap.pixels.each do |pixel|
          colour = case pixel.colour

          when "W"
            white
          when "C"
            cyan
          when "B"
            blue
          when "M"
            magenta
          when "R"
            red
          when "Y"
            yellow
          when "G"
            green
          when "K"
            black
          else
            raise "Invalid color: #{pixel.colour}"
          end
          png.compose_pixel(pixel.x, pixel.y, colour)
        end

        png.save(buffer_outfile)

        expect(Digest::MD5.file(buffer_outfile).hexdigest).to eq Digest::MD5.file("spec/fixtures/colored_buffer.png").hexdigest
      end

      it "exports barcode to zint bitmap" do
        bitmap = barcode.to_buffer(raw_bitmap: true)

        expected_bitmap = File.read("spec/fixtures/barcode_raw_bitmap.txt")
        expect(bitmap).to eq expected_bitmap
      end

      it "exports barcode as vector from given value" do
        vector_struct = barcode.to_vector

        expect(vector_struct.is_a?(Zint::Structs::Vector)).to be true
      end

      it "exports barcode as vector from input file" do
        vector_struct = barcode_with_input_file.to_vector

        expect(vector_struct.is_a?(Zint::Structs::Vector)).to be true
      end
    end

    describe "#type=" do
      it "changes symbology correctly" do
        code_128_svg_file = barcode.to_memory_file(extension: ".svg")
        barcode.type = Zint::BARCODE_CODE39
        code_128b_svg_file = barcode.to_memory_file(extension: ".svg")

        expect(code_128_svg_file).not_to eq code_128b_svg_file
      end
    end

    describe "error handling" do
      it "raises matching error" do
        barcode = described_class.new(value: "A" * 4096)
        expect { barcode.to_buffer }.to raise_error(Zint::ErrorTooLong, "Error 340: Input too long (160 character maximum)")
      end
    end
  end
end
