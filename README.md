# FreeForm

FreeForm is a gem designed to give you total control over form objects, allowing you to map form objects to domain objects in any way that you see fit.  The primary benefits are:
  * Decoupling form objects from domain models
  * Allowing form-specific validations, while respecting model validations
  * Simply composing multi-model forms
  * Removing the ugliness of `accepts_nested_attributes_for`

FreeForm is designed primarily with Rails in mind, but it should work on any Ruby framework.  FreeForm is compatible with most form gems, including simpleform, and formbuilder

**FreeForm will not work with Ryan Bate's nested_form gem, but provides its own identical behavior**

## Installation

Add this line to your application's Gemfile:

    gem 'freeform', '>= 1.0.0'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install freeform

## How It Works

FreeForm creates model objects that can hold 1-*n* models, exposing whatever attributes you wish from each model, and delegating those assignments back to the models themselves.  This means that one form can be used just as easily to support parent/child models, multiple unrelated models, etc.  Your database relationships can change, and your forms won't have to.

**Example**

```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address

  property :username,              :on => :user
  property :email,                 :on => :user
  property :password,              :on => :user

  property :street,                :on => :address
  property :city,                  :on => :address
  property :state,                 :on => :address
  property :zip_code,              :on => :address
end

class User < ActiveRecord::Base
  has_one :address
  ...
end

class Address < ActiveRecord::Base
  belongs_to :user
  ...
end

user = User.new
RegistrationForm.new(:user => user, :address => user.build_address)
```
**Oh No!**
Our domain model has changed, and we needs users to have multiple addresses!  We'll change our model...but our form remains the same.

```ruby
class User < ActiveRecord::Base
  has_many :addresses
  ...
end

class Address < ActiveRecord::Base
  belongs_to :user
  ...
end

user = User.new
RegistrationForm.new(:user => user, :address => user.addresses.build)
```

## Defining Forms

FreeForm doesn't assume a lot, so you need to tell it:
  * The names of the models it's going to be mapping (specified as `form_model` or `form_models`)
  * The properties of the form, and which model they map to (specified as `property` or `properties`).  Properties that don't map to a model are considered to be just form attributes.
  * How to validate, if at all (see below)

```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address

  property :username,              :on => :user
  property :email,                 :on => :user
  property :password,              :on => :user

  property :street,                :on => :address
  property :city,                  :on => :address
  property :state,                 :on => :address
  property :zip_code,              :on => :address
end

class User < ActiveRecord::Base
  has_one :address
  ...
end

class Address < ActiveRecord::Base
  belongs_to :user
  ...
end

user = User.new
RegistrationForm.new(:user => user, :address => user.build_address)
```
## Assigning Parameters

Forms can be populated either directly through accessors (e.g. `form.street = "123 Main St."`), or using the `assign_params()` or `fill()` methods.

```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address

  property :username,              :on => :user
  property :street,                :on => :address
end

form = RegistrationForm.new(:user => User.new, :address => Address.new)
form.assign_params({ :username => "myusername", :street => "1600 Pennsylvania Ave." })
# fill() is just an alias for assign_params
form.fill({ :username => "myusername", :street => "1600 Pennsylvania Ave." })
```

## Saving & Marking For Destruction

Calling `form.save` will validate the form, then make a save call to each model defined in the form (and each nested form).  A call to `save!` behaves the same way.

```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address

  property :username,              :on => :user
  property :street,                :on => :address
end

form = RegistrationForm.new(:user => User.new, :address => Address.new)
form.fill({ :username => "myusername", :street => "1600 Pennsylvania Ave." })
form.save # SAVES the User and Address models
```

Additionally, each model has a method you can add called `allow_destroy_on_save`.  This method adds an accessor called `_destroy` (also aliased as `marked_for_destruction`) that can be set.  If this is set, each form in the model will receive a `destroy` call on save.

```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address
  allow_destroy_on_save

  property :username,              :on => :user
  property :street,                :on => :address
end

form = RegistrationForm.new(:user => User.new, :address => Address.new)
form.fill({ :username => "myusername", :street => "1600 Pennsylvania Ave.", :_destroy => "1" })
form.save # DESTROYS the User and Address models
```
This method is necessary if you use the nested_form gem for dynamically creating/deleting models.

## Form Validations

FreeForm handles validations wherever you define them.  If you want to check model validations, simply specify that option in your form definition

```ruby
class UserForm < FreeForm::Form
  form_models :user
  validate_models  # This will check to see that the :user model itself is valid

  property :username,              :on => :user
  property :email,                 :on => :user
  property :current_password

  # But you can also validate in the form itself!
  validates :email, :presence => true
  validate :valid_current_password

  def valid_current_password
    user.password == current_password
  end
end
```
Personally, I use validations in both places.  My domain models have their own validations, which I use for things that are universally true of that model (e.g. email is correctly formatted).  Some forms have validations though that are specific to that form, and they live in the form itself (see above example with `current_password`)

## Nesting Forms

One of the benefits of forms objects is that you don't have to mess with models accepting nested attributes.
But sometimes, you need to be able to support a collection of unknown size (e.g. a user with many phone numbers).
Since FreeForm makes no assumptions about your domain models, we nest forms themselves.

```ruby
class UserForm < FreeForm::Form
  form_models :user

  property :username,              :on => :user
  property :email,                 :on => :user

  has_many :phone_numbers, :class => PhoneNumberForm, :default_initializer => :phone_initializer

  def phone_initializer
    { :phone => user.phone_numbers.build }
  end
end

class PhoneNumberForm < FreeForm::Form
  form_models :phone

  property :area_code,              :on => :phone
  property :number,                 :on => :phone
end
```
**Note:**  The method `nested_form` is also aliased as `has_many` and `has_one`, if you prefer the expressiveness of that syntax.  The functionality is the same in any case.

When using a nested form, the form starts with **no** nested forms pre-built.  FreeForm provides a method called `build_#{nested_form_model}` (e.g. `build_phone_numbers`) that you can use to build a nested form.  You must provide the initializer:
```ruby
form = UserForm.new(:user => User.new)
form.build_phone_number # Now the nested form is created
```

**Ryan Bates' nested_form gem functionality**
FreeForm has a built in implementation of the functionality from Ryan Bates' *nested_form* gem.
When building a form, just use the method `freeform_for...`

** Example **
```ruby
current_user               # => #<User:0x100124b88>
current_user.phone_numbers # => [#<Phone:0x100194867>, #<Phone:0x100100cd4>]

class UserForm < FreeForm::Form
  form_models :user

  property :username,              :on => :user
  property :email,                 :on => :user

  has_many :phone_numbers, :class => PhoneNumberForm, :default_initializer => :phone_initializer

  def phone_initializer
    { :phone => user.phone_numbers.build }
  end
end

class PhoneNumberForm < FreeForm::Form
  form_models :phone

  property :area_code,              :on => :phone
  property :number,                 :on => :phone
end

form = UserForm.new(:user => current_user)
```

Will the current_user's phone numbers automatically appear as nested forms? **No.**
If you want them there, put them there, like this:

```ruby
current_user.phone_numbers.each do |phone_number|
  form.build_phone_number(:phone => phone_number)
end
```

## Extras!

I'm open to trying to build out little helper features wherever possible. Right now, FreeForm comes with one handy option called `form_input_key`.  Setting this determines the parameter key that your forms are rendered with in Rails.

*Why use this?*
Well, I like to keep my form keys fairly concise, but in a bigger application I often end up namespacing my forms.  And changing namespaces sometimes breaks Cucumber specs, which might be hardcoded to find a particular ID.  No more!

```ruby
class MyScope::UserForm < FreeForm::Form
  form_input_key :user # Sets the parameter key for HTML rendering.
  form_models :user

  property :email, :on => :user
end
```
Would render with HTML input fields like
`<input id="user_email" ... name="user[email]"></input>` instead of
`<input id="my_scope_user_form_email" ... name="my_scope_user_form[email]"></input>`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
