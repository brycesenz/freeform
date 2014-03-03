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
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_0_name']", visible: true)
          click_link 'Add new task'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_1_name']", visible: true)
          click_link 'Add new task'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_2_name']", visible: true)
        end

        it 'removes fields, but increments count on next add' do
          visit url
          click_link 'Add new task'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_0_name']", visible: true)
          click_link 'Remove'
          page.should have_no_selector(:xpath, "//input[@id='project_tasks_attributes_0_name']", visible: true)
          click_link 'Add new task'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_1_name']", visible: true)
          click_link 'Add new task'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_2_name']", visible: true)
        end
      end

      context 'after application submission', :failing => true do
        it 'emits general remove event' do
          visit url
          click_link 'Add new task'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_0_name']", visible: true)
          click_link 'Remove'
          page.should have_no_selector(:xpath, "//input[@id='project_tasks_attributes_0_name']", visible: true)
          click_button 'Submit'
          page.should have_selector(:xpath, "//input[@id='project_tasks_attributes_0__destroy' and @value='1']", visible: false)
        end
      end
    end
  end
end
