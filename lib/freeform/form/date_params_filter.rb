module FreeForm
  class DateParamsFilter
    def initialize(*args)
    end

    def call(params)
      date_attributes = {}

      params.each do |attribute, value|
        if value.is_a?(Hash)
          call(value) # TODO: #validate should only handle local form params.
        elsif matches = attribute.match(/^(\w+)\(.i\)$/)
          date_attribute = matches[1]
          date_attributes[date_attribute] = params_to_date(
            params.delete("#{date_attribute}(1i)"),
            params.delete("#{date_attribute}(2i)"),
            params.delete("#{date_attribute}(3i)")
          )
        end
      end
      params.merge!(date_attributes)
    end

  private
    def params_to_date(year, month, day)
      day ||= 1 # FIXME: is that really what we want? test.
      begin # TODO: test fails.
        return Date.new(year.to_i, month.to_i, day.to_i)
      rescue ArgumentError => e
        return nil
      end
    end
  end
end
