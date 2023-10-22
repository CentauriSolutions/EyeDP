import * as WebAuthnJSON from "./@github/webauthn-json"
// import { showMessage } from "messenger";


function getCSRFToken() {
  var CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  if (CSRFSelector) {
    return CSRFSelector.getAttribute("content")
  } else {
    return null
  }
}

function callback(url, body) {
  fetch(url, {
    method: "POST",
    body: JSON.stringify(body),
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    credentials: 'same-origin'
  }).then(function(response) {
    if (response.ok) {
      window.location.replace("/profile/authentication_devices")
    } else if (response.status < 500) {
      console.log(response)
      response.text().then(alert);
    } else {
      alert("Sorry, something wrong happened.");
    }
  });
}

function create_webauthn(callbackUrl, credentialOptions) {
  WebAuthnJSON.create({ "publicKey": credentialOptions }).then(function(credential) {
    callback(callbackUrl, credential);
  }).catch(function(error) {
    console.log(error);

  });

  console.log("Creating new public key credential...");
}

function get_webauthn(credentialOptions) {
  console.log(credentialOptions)
  WebAuthnJSON.get({ "publicKey": credentialOptions }).then(function(credential) {
    console.log(credential)
    callback(`/users/sign_in?user[remember_me]=${remember_me}`, credential);
  }).catch(function(error) {
    alert(error);
  });

  console.log("Getting public key credential...");
}

// TODO: Trigger this off a button click when the nick name set
$('#register-webauthn').on('click', function(evt){
  evt.preventDefault()
  fetch('/users/webauthn', {method: 'GET', headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "X-CSRF-Token": getCSRFToken()
  }}).then(response => response.json()).then(function(publicKeyCredentialRequestOptions) {
    var credential_nickname = $("input#credential_nickname").val();
    // publicKeyCredentialRequestOptions['credential_nickname'] = credential_nickname
    create_webauthn(`/users/webauthn?credential_nickname=${credential_nickname}`, publicKeyCredentialRequestOptions)
  })

})

$('#run_webauthn').on('click', function(evt) {
  evt.preventDefault()
  get_webauthn(options)
})

