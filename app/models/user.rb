class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable,
         :trackable,
         :validatable,
         :timeoutable,
         :lockable,
         :confirmable,
         :invitable,
         :suspendable # in signon/lib/devise/models/suspendable.rb
end
