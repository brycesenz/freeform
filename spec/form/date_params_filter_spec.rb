require 'spec_helper'
require 'freeform/form/date_params_filter'

describe FreeForm::DateParamsFilter do
  describe "#call", :call => true do
    let(:params) do
      {
        :company_name => "dummycorp",
        :project_name => "railsapp",
        "due_date(1i)" => "2014",
        "due_date(2i)" => "10",
        "due_date(3i)" => "30",
        :tasks_attributes => {
          "0" => {
            :name => "task_1",
            "start_date(1i)" => "2012",
            "start_date(2i)" => "1",
            "start_date(3i)" => "2",
          },
          "1" => {
            :name => "task_2",
            "end_date(1i)" => "2011",
            "end_date(2i)" => "12",
          },
        },
      }
    end

    subject { described_class.new.call(params) }

    it "should have filtered all date params into Date objects" do
      subject.should eq(
        {
          :company_name => "dummycorp",
          :project_name => "railsapp",
          "due_date" => Date.new(2014, 10, 30),
          :tasks_attributes => {
            "0" => {
              :name => "task_1",
              "start_date" => Date.new(2012, 1, 2),
            },
            "1" => {
              :name => "task_2",
              "end_date" => Date.new(2011, 12, 1),
            },
          },
        }
      )
    end
  end
end