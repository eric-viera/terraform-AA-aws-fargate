resource "aws_cognito_user_pool" "users-pool" {
  name                     = "${var.name}-user-pool"
  auto_verified_attributes = [ "email" ]
  mfa_configuration        = "OPTIONAL"
  username_attributes = [ "email" ]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = false
    invite_message_template {
      email_message = "Welcome to the webapp, {username}, your temporay password is: {####}."
      email_subject = "Webapp invitation"
      sms_message   = "Welcome to the webapp, {username}, your temporay password is: {####}."
    }
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  software_token_mfa_configuration {
    enabled = true
  }
  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
    email_message = "This is your email address confirmation code: {####}"
    email_message_by_link = "{##Click Here##} to confirm your email address"
    email_subject = "confirmation code"
    email_subject_by_link = "Confirmation link"
    sms_message = "Your verification code is {####}"
  }
}

resource "aws_cognito_user_pool_client" "pool-client" {
  name                                 = "${var.name}-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.users-pool.id
  callback_urls                        = [ "http://localhost" ]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = [ "COGNITO" ]
}

resource "aws_cognito_user_pool_domain" "user-pool-domain" {
  domain = "${var.name}-viera"
  user_pool_id = aws_cognito_user_pool.users-pool.id
}