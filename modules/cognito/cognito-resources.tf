resource "aws_cognito_user_pool" "users-pool" {
  name = "${var.name}-user-pool"
  account_recovery_setting {
    recovery_mechanism {
      name = "verified_email"
      priority = 1
    }
  }
  mfa_configuration = "OPTIONAL"
  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
  }
  software_token_mfa_configuration {
    enabled = true
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
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