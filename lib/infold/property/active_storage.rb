module Infold
  class ActiveStorage
    include ActiveModel::Model

    attr_reader :field
    attr_accessor :kind,
                  :thumb

    def initialize(field, **attrs)
      @field = field
      super(attrs)
    end

    def build_thumb(**attrs)
      @thumb = ActiveStorageThumb.new(**attrs)
    end

    def kind_image?
      kind.to_s == 'image'
    end

    def kind_file?
      !kind_image?
    end

    class ActiveStorageThumb
      include ActiveModel::Model

      attr_accessor :kind,
                    :width,
                    :height
    end
  end
end