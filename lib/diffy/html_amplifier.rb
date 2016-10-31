module Diffy
  class HtmlAmplifier

    REFERENCE_PATTERN = %r{^[+-](\w+)_id}
    ID_PATTERN = %r{<strong>(\w+)<\/strong>}

    def initialize(html_string, fields = true)
      @html_string = html_string
      @fields =
        if fields == true
          [:name]
        elsif fields.is_a?(Array) && !fields.empty?
          fields
        end
    end

    def amplify
      reference_match = @html_string.match(REFERENCE_PATTERN)

      if reference_match && @fields
        begin
          model = reference_match[1].classify.constantize
          id = @html_string.match(ID_PATTERN)[1].to_i
          instance = model.find(id)

          @fields.each do |field|
            if instance.has_attribute?(field)
              @html_string += ", #{field} = <strong>#{instance.send(field)}" \
                              '</strong>'
            end
          end
        rescue => error
          puts 'RESCUE'
          puts error.to_s
          @html_string
        end
      end

      @html_string
    end
  end
end
