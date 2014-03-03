require 'spec_helper'

describe 'Full Behavior', :js => true do
  include Capybara::DSL

  [:jquery].each do |js_framework|

    url = case js_framework
    when :jquery then '/projects/new'
    end

    context "with #{js_framework}" do
      context 'adding/removing fields' do
        it 'adds fields and increments count' do
          visit url
          click_link 'Add new task'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(1)
          click_link 'Add new task'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(2)
          click_link 'Add new task'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(3)
        end

        it 'removes fields' do
          visit url
          click_link 'Add new task'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(1)
          click_link 'Remove'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(0)
          click_link 'Add new task'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(1)
        end
      end

      context 'after application submission' do
        it 'emits general remove event' do
          visit url
          click_link 'Add new task'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(1)
          click_link 'Remove'
          all("input[id^='project_tasks_attributes_']", visible: true).count.should eq(0)
          click_button 'Submit'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_0__destroy' and @value='1']", visible: false)
        end
      end
    end
  end
end
