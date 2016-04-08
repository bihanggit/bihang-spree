module Spree
  CheckoutController.class_eval do
    before_filter :bihang_redirect, :only => [:update]

    private
    def bihang_redirect
      return unless (params[:state] == "payment") && params[:order][:payments_attributes]

      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      if payment_method.kind_of?(Spree::PaymentMethod::Bihang)
        redirect_to spree_bihang_redirect_url(:payment_method_id => payment_method.id)
      end
    end
  end
end