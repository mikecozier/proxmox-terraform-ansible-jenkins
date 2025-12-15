pipeline {
  agent any

  environment {
    PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
    PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
  }

  parameters {
    booleanParam(name: 'APPLY', defaultValue: false, description: 'Run terraform apply + Ansible')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Terraform Init & Plan') {
      steps {
        sh '''
          terraform init -input=false
          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          terraform plan -out=plan.out
        '''
      }
    }

    stage('Terraform Apply') {
      when { expression { return params.APPLY } }
      steps {
        sh '''
          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          terraform apply -auto-approve plan.out
        '''
      }
    }
  }

  options { timestamps() }
}

