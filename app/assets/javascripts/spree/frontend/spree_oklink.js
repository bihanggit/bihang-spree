SpreeOklink = {
  doOnSiteCheckout: function() {
    
    $('#checkout_form_payment input.continue').hide();
    $('div[data-hook="checkout_payment_step"]').html("<iframe src=\"" + SpreeOklink.checkoutUrl + "\" style=\"width: 500px; height: 160px; border: none; overflow: hidden;\" scrolling=\"no\" allowtransparency=\"true\" frameborder=\"0\"></iframe>" + 
      "<p><a href=\"" + SpreeOklink.cancelUrl + "\">Cancel and choose another payment method</a></p>");
  }
}

$(document).ready(function() {
  $('#checkout_form_payment input.continue').click(function (e) {
    checkedPaymentMethod = $('div[data-hook="checkout_payment_step"] input[type="radio"]:checked');
    
    if (checkedPaymentMethod.val() == SpreeOklink.paymentMethodId && !SpreeOklink.useOffSite) {
      // On-site checkout!
      SpreeOklink.doOnSiteCheckout();
      return false;
    } else {
      return true;
    }
  });
})

window.addEventListener('message', receiveMessage, false);

// Listen for messages from the on-site payment iframe
function receiveMessage(event) {

  if (event.origin == 'https://oklink.com') {
    var event_type = event.data.split('|')[0];
    if (event_type == 'oklink_payment_complete') {

      // Redirect to success url (wait 1 second for callback to arrive)
      setTimeout(function() {
        window.location = SpreeOklink.successUrl;
      }, 1000);
    }
  }
}