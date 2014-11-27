module Spree
	class OklinkTrancation < ActiveRecord::Base
		has_many :payments, :as => :source
		
	    def actions
	      []
	    end

	end


end
