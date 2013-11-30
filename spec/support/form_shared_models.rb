module FormSharedModels
  shared_context "with form models" do
    let(:user_class) do
      Class.new(Module) do
        include ActiveModel::Validations
        def self.model_name; ActiveModel::Name.new(self, nil, "user") end
  
        attr_accessor :username
        attr_accessor :email
        validates :username, :presence => true
  
        def save; return valid? end
        alias_method :save!, :save
        def destroy; return true end
      end
    end
  
    let(:address_class) do
      Class.new(Module) do
        include ActiveModel::Validations
        def self.model_name; ActiveModel::Name.new(self, nil, "address") end
  
        attr_accessor :street
        attr_accessor :city
        attr_accessor :state
        validates :street, :presence => true
        validates :city, :presence => true
        validates :state, :presence => true
  
        def save; return valid? end
        alias_method :save!, :save
        def destroy; return true end
      end
    end
  
    let(:phone_class) do
      Class.new(Module) do
        include ActiveModel::Validations
        def self.model_name; ActiveModel::Name.new(self, nil, "phone") end
  
        attr_accessor :area_code
        attr_accessor :number
        validates :number, :presence => true
  
        def save; return valid? end
        alias_method :save!, :save
        def destroy; return true end
      end
    end
  
    let(:form_class) do
      klass = Class.new(FreeForm::Form) do
        form_input_key :user
        form_models :user, :address
        validate_models
        allow_destroy_on_save
        
        property :username, :on => :user      
        property :email,    :on => :user
        property :street, :on => :address      
        property :city,   :on => :address      
        property :state,  :on => :address      
  
        has_many :phone_numbers, :class_initializer => :phone_number_initializer do
          form_model :phone
          validate_models
          allow_destroy_on_save
          
          property :area_code, :on => :phone
          property :number,    :on => :phone
        end
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("AcceptanceForm", klass)
      $VERBOSE = v
      klass
    end
  
    let(:form) do
      form_class.phone_number_initializer = lambda { {:phone => phone_class.new} }
      form_model = form_class.new( :user => user_class.new, :address => address_class.new)
      form_model.build_phone_number
      form_model
    end
  end
end

RSpec.configure do |config|
  config.extend FormSharedModels
end
