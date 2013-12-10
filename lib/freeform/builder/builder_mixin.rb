require 'nested_form/builders'

module FreeForm
  module BuilderMixin
    include NestedForm::BuilderMixin

    # Adds a link to insert a new associated records. The first argument is the name of the link, the second is the name of the association.
    #
    # f.link_to_add("Add Task", :tasks)
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    # <%= f.link_to_add(:tasks, :class => "add_task", :href => new_task_path) do %>
    # Add Task
    # <% end %>
    #
    # You can also pass <tt>model_object</tt> option with an object for use in
    # the blueprint, e.g.:
    #
    # <%= f.link_to_add(:tasks, :model_object => Task.new(:name => 'Task')) %>
    #
    # See the README for more details on where to call this method.
    def link_to_add(*args, &block)
      options = args.extract_options!.symbolize_keys
      association = args.pop

      unless object.respond_to?("#{association}_attributes=")
        raise ArgumentError, "Invalid association. Make sure that accepts_nested_attributes_for is used for #{association.inspect} association."
      end

      #TODO: THis is where things are going wrong!!
      model_object = options.delete(:model_object) do
        reflection = object.class.reflect_on_association(association)
        reflection.klass.new
      end

      options[:class] = [options[:class], "add_nested_fields"].compact.join(" ")
      options["data-association"] = association
      options["data-blueprint-id"] = fields_blueprint_id = fields_blueprint_id_for(association)
      args << (options.delete(:href) || "javascript:void(0)")
      args << options

      @fields ||= {}
      @template.after_nested_form(fields_blueprint_id) do
        blueprint = {:id => fields_blueprint_id, :style => 'display: none'}
        block, options = @fields[fields_blueprint_id].values_at(:block, :options)
        options[:child_index] = "new_#{association}"
        blueprint[:"data-blueprint"] = fields_for(association, model_object, options, &block).to_str
        @template.content_tag(:div, nil, blueprint)
      end
      @template.link_to(*args, &block)
    end

    # Adds a link to remove the associated record. The first argment is the name of the link.
    #
    # f.link_to_remove("Remove Task")
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    # <%= f.link_to_remove(:class => "remove_task", :href => "#") do %>
    # Remove Task
    # <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_remove(*args, &block)
      options = args.extract_options!.symbolize_keys
      options[:class] = [options[:class], "remove_nested_fields"].compact.join(" ")

      # Extracting "milestones" from "...[milestones_attributes][...]"
      md = object_name.to_s.match(/(\w+)_attributes\](?:\[[\w\d]+\])?$/)
      association = md && md[1]
      options["data-association"] = association

      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      hidden_field(:_destroy) << @template.link_to(*args, &block)
    end
  end
end