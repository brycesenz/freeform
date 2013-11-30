require 'spec_helper'

describe FreeForm::Form do
  # This context is in the spec/support folder
  include_context "with form models"
  
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

  describe "validations", :validations => true do
    context "with invalid attributes" do
      let(:attributes) do {
        :username => "dummyuser",
        :email => "test@email.com",
        :street => nil,
        :city => "Portland",
        :state => "Oregon",
        :phone_numbers_attributes => {
          "0" => {
            :number => "123-4567"
          },
          "1" => {
            :area_code => "202"
          }
        } }
      end
      
      before(:each) do
        form.fill(attributes)
        form.valid?
      end
      
      it "should be invalid" do
        form.should_not be_valid
      end

      it "should have errors on street" do
        form.errors[:street].should eq(["can't be blank"])
      end

      it "should have errors on first phone number's area code" do
        form.phone_numbers.first.errors[:area_code].should be_empty
      end

      it "should have errors on first phone number's number" do
        form.phone_numbers.last.errors[:number].should eq(["can't be blank"])
      end

      it "should return false on 'save'" do
        form.save.should be_false
      end

      it "should raise error on 'save!'" do
        expect{ form.save!.should be_false }.to raise_error(FreeForm::FormInvalid)
      end
    end

    context "with valid attributes" do
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
      
      it "should be valid" do
        form.should be_valid
      end

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
      
      describe "destroying on save", :destroy_on_save => true do
        describe "save" do
          it "destroys models on save if set" do
            form._destroy = true
            form.user.should_receive(:destroy).and_return(true)
            form.address.should_receive(:destroy).and_return(true)
            form.phone_numbers.first.phone.should_receive(:save).and_return(true)
            form.save
          end
    
          it "destroys models on save if set through attribute" do
            form.fill({:_destroy => "1"})
            form.user.should_receive(:destroy).and_return(true)
            form.address.should_receive(:destroy).and_return(true)
            form.phone_numbers.first.phone.should_receive(:save).and_return(true)
            form.save
          end

          it "destroys nested models on save if set" do
            form.phone_numbers.first._destroy = true
            form.user.should_receive(:save).and_return(true)
            form.address.should_receive(:save).and_return(true)
            form.phone_numbers.first.phone.should_receive(:destroy).and_return(true)
            form.save
          end
        end
        
        describe "save!" do
          it "destroys models on save! if set" do
            form._destroy = true
            form.user.should_receive(:destroy).and_return(true)
            form.address.should_receive(:destroy).and_return(true)
            form.phone_numbers.first.phone.should_receive(:save!).and_return(true)
            form.save!
          end
  
          it "destroys models on save! if set" do
            form.fill({:_destroy => "1"})
            form.user.should_receive(:destroy).and_return(true)
            form.address.should_receive(:destroy).and_return(true)
            form.phone_numbers.first.phone.should_receive(:save!).and_return(true)
            form.save!
          end

          it "destroys nested models on save! if set" do
            form.phone_numbers.first._destroy = true
            form.user.should_receive(:save!).and_return(true)
            form.address.should_receive(:save!).and_return(true)
            form.phone_numbers.first.phone.should_receive(:destroy).and_return(true)
            form.save!
          end
        end
      end
    end
  end
end