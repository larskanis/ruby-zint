module Zint
  class Code49 < Barcode
    def initialize(value: nil, input_file: nil, options: {})
      super(value: value, input_file: input_file, type: Zint::BARCODE_CODE49, options: options)
    end
  end
end
