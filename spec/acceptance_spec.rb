require 'spec_helper'

describe FreeForm::Form do
  let(:user_class) do
    Class.new(Module) do
      include ActiveModel::Validations
      def self.model_name; ActiveModel::Name.new(self, nil, "user") end

      attr_accessor :username
      attr_accessor :email
      validates :username, :presence => true

      def save; return valid? end
      alias_method :save!, :save
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
    end
  end

  let(:form_class) do
    klass = Class.new(FreeForm::Form) do
      form_input_key :user
      form_models :user, :address
      
      property :username, :on => :user      
      property :email,    :on => :user      
      property :street, :on => :address      
      property :city,   :on => :address      
      property :state,  :on => :address      

      has_many :phone_numbers do
        form_model :phone
        
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
    form_model = form_class.new( 
      :user => user_class.new, 
      :address => address_class.new,
      :phone_numbers_form_initializer => lambda { { :phone => phone_class.new } }
      )
    form_model.build_phone_number
    form_model
  end

  describe "form initialization", :initialization => true do
    it "initializes with user model" do
      form.user.should be_a(user_class)
    end

    it "initializes with address model" do
      form.address.should be_a(address_class)
    end

    it "initializes with phone model" do
      form.phone_numbers.first.phone.should be_a(phone_class)
    end
  end

  describe "building nested models", :nested_models => true do
    it "can build multiple phone_numbers" do
      form.phone_numbers.count.should eq(1)
      form.build_phone_number
      form.build_phone_number
      form.phone_numbers.count.should eq(3)
    end

    it "build new models for each phone numbers" do
      form.build_phone_number
      phone_1 = form.phone_numbers.first.phone
      phone_2 = form.phone_numbers.last.phone
      phone_1.should_not eq(phone_2)
    end
  end

  describe "assigning parameters", :assign_params => true do
    let(:attributes) do {
      :username => "dummyuser",
      :email => "test@email.com",
      :street => "1 Maple St.",
      :city => "Portland",
      :state => "Oregon",
      :phone_numbers_attributes => {
        "0" => {
          :area_code => "555",
          :number => "123-4567"
        },
        "1" => {
          :area_code => "202",
          :number => "876-5432"
        }
      } }
    end
    
    before(:each) do
      form.fill(attributes)
    end
    
    it "assigns username" do
      form.username.should eq("dummyuser")
    end

    it "assigns street" do
      form.street.should eq("1 Maple St.")
    end

    it "assigns phone number area code" do
      form.phone_numbers.first.phone.area_code.should eq("555")
    end

    it "builds new phone number automatically" do
      form.phone_numbers.count.should eq(2)
    end

    it "assigns second phone number area code" do
      form.phone_numbers.last.phone.area_code.should eq("202")
    end
  end

  describe "saving", :saving => true do
    context "form is invalid" do
      it "should return false on 'save'" do
        form.save.should be_false
      end

      it "should raise error on 'save!'" do
        expect{ form.save!.should be_false }.to raise_error
      end
    end

    context "form is valid" do
      it "should return true on 'save', and call save on other models" do
        form.user.should_receive(:save).and_return(true)
        form.address.should_receive(:save).and_return(true)
        form.phone_numbers.first.phone.should_receive(:save).and_return(true)
        form.save
      end

      it "should return true on 'save!', and call save! on other models" do
        form.user.should_receive(:save!).and_return(true)
        form.address.should_receive(:save!).and_return(true)
        form.phone_numbers.first.phone.should_receive(:save!).and_return(true)
        form.save!
      end
    end
  end
end