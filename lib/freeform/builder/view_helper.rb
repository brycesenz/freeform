module FreeForm
  module ViewHelper
    def freeform_for(*args, &block)
      options = args.extract_options!.reverse_merge(:builder => FreeForm::Builder)
      form_for(*(args << options)) do |f|
        capture(f, &block).to_s << after_freeform_callbacks
      end
    end

    if defined?(FreeForm::SimpleBuilder)
      def simple_freeform_for(*args, &block)
        options = args.extract_options!.reverse_merge(:builder => FreeForm::SimpleBuilder)
        simple_form_for(*(args << options)) do |f|
          capture(f, &block).to_s << after_freeform_callbacks
        end
      end
    end

    if defined?(FreeForm::FormtasticBuilder)
      def semantic_freeform_for(*args, &block)
        options = args.extract_options!.reverse_merge(:builder => FreeForm::FormtasticBuilder)
        semantic_form_for(*(args << options)) do |f|
          capture(f, &block).to_s << after_freeform_callbacks
        end
      end
    end

    if defined?(FreeForm::FormtasticBootstrapBuilder)
      def semantic_bootstrap_freeform_for(*args, &block)
        options = args.extract_options!.reverse_merge(:builder => FreeForm::FormtasticBootstrapBuilder)
        semantic_form_for(*(args << options)) do |f|
          capture(f, &block).to_s << after_freeform_callbacks
        end
      end
    end

    def after_freeform(association, &block)
      @associations ||= []
      @after_freeform_callbacks ||= []
      unless @associations.include?(association)
        @associations << association
        @after_freeform_callbacks << block
      end
    end

  private
    def after_freeform_callbacks
      @after_freeform_callbacks ||= []
      fields = []
      while callback = @after_freeform_callbacks.shift
        fields << callback.call
      end
      fields.join(" ").html_safe
    end
  end
end