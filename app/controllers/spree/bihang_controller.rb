require 'HTTParty'
require 'openssl'

module Spree
  class BihangController < StoreController
  	include HTTParty
  	OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
	def redirect
		order = current_order || raise(ActiveRecord::RecordNotFound)

		if order.state != "payment"
			redirect_to root_url() 
			return
		end

		# Create Bihang button code
		secret_token = SecureRandom.base64(30)
		button_params = { 
				:name => "Order #%s" % order.number,
				:price => (float)order.total,
				:price_currency => order.currency,
				:callback_url => spree_bihang_callback_url(:payment_method_id => params[:payment_method_id], :secret_token => secret_token),
				:success_url => spree_bihang_success_url(:payment_method_id => params[:payment_method_id], :order_num => order.number),
				}

        key = payment_method.preferred_api_key
		secret = payment_method.preferred_api_secret				
		client = make_bihang_request :post, "/buttons", button_params
		button = client.buttonsButton(button_params)
		code = result["button"]["id"]

		if code
			# Add a "processing" payment that is used to verify the callback
			transaction = BihangTrancation.new
			transaction.button_id = code
			transaction.secret_token = secret_token
			payment = order.payments.create({:amount => order.total,
											:source => transaction,
											:payment_method => payment_method })
			payment.started_processing!

			use_off_site = payment_method.preferred_use_off_site_payment_page
			redirect_to "https://bihang.com/merchant/mPayOrderStemp1.do?buttonid=%1$s" % [code]
		else
			redirect_to edit_order_checkout_url(order, :state => 'payment'),
                    :notice => Spree.t(:spree_bihang_checkout_error)
		end
	end

	def callback

		# Download order information from bihang (do not trust sent order information)
		cb_order_id = params["order"]["id"]
		cb_order = make_bihang_request :get, "/orders/%s" % cb_order_id, {}

		if cb_order.nil?
 			render text: "Invalid order ID", status: 400
 			return
		end

		cb_order = cb_order["order"]

		if cb_order["status"] != "completed"
 			render text: "Invalid order status", status: 400
 			return
		end

		# Fetch Spree order information, find relevant payment, and verify button_id
		order_id = cb_order["custom"]
		order = Spree::Order.find(order_id)
		button_id = cb_order["button"]["id"]
		payments = order.payments.where(:state => "processing",
                                      :payment_method_id => payment_method)
		payment = nil
		payments.each do |p|
			if p.source.button_id == button_id
				payment = p
			end
 		end

 		if payment.nil?
 			render text: "No matching payment for order", status: 400
 			return
 		end

 		# Verify secret_token
 		if payment.source.secret_token != params[:secret_token]
 			render text: "Invalid secret token", status: 400
 			return
 		end

 		# Now that this callback has been verified, process the payment!
 		transaction = payment.source
 		transaction.order_id = cb_order_id
 		transaction.save

 		# Make payment pending -> make order complete -> make payment complete -> update order
 		payment.pend!
 		order.next
 		if !order.complete?
 			render text: "Could not transition order: %s" % order.errors
 			return
 		end
 		payment.complete!
 		order.update!

 		# Successful payment!
 		render text: "Callback successful"

	end

	def cancel

		order = current_order || raise(ActiveRecord::RecordNotFound)

		# Void the 'pending' payment created in redirect
		# If doing an on-site checkout params will be nil, so just
		# cancel all bihang payments (it is unlikely there will be more than one)
		button_id = params["order"]["button"]["id"] rescue nil
		payments = order.payments.where(:state => "pending",
                                      :payment_method_id => payment_method)
		payments.each do |payment|
			if payment.source.button_id == button_id || button_id.nil?
				payment.void!
			end
 		end

		redirect_to edit_order_checkout_url(order, :state => 'payment'),
			:notice => Spree.t(:spree_bihang_checkout_cancelled)
	end

	def success

		order = Spree::Order.find_by_number(params[:order_num]) || raise(ActiveRecord::RecordNotFound)

		if order.complete?
          	session[:order_id] = nil # Reset cart
			redirect_to spree.order_path(order), :notice => Spree.t(:order_processed_successfully)
		end

		# If order not complete, wait for callback to come in... (page will automatically refresh, see view)
	end

	private

	def payment_method
		m = Spree::PaymentMethod.find(params[:payment_method_id])
		if !(m.is_a? Spree::PaymentMethod::Bihang)
			raise "Invalid payment_method_id"
		end
		m
	end

	# the bihang-ruby gem is not used because of its dependence on incompatible versions of the money gem
	def make_bihang_request verb, path, options

		if key.nil? || secret.nil?
			raise "Please enter an API key and secret in Spree payment method settings"
		end

		base_uri = "https://www.bihang.com/api/v1"
		nonce = (Time.now.to_f * 1e6).to_i
		message = nonce.to_s + '/api/v1' + path + options.to_json
		signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'), secret, message)

		headers = {
			'KEY' => key,
			'SIGNATURE' => signature,
			'NONCE' => nonce.to_s,
			"Content-Type" => "application/json",
		}

		r = self.class.send(verb, base_uri + path, {headers: headers, body: options.to_json})
		JSON.parse(r.body)
	end
  end
end