pipeline {
  agent any
  environment {
    PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
    PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
  }
  parameters {
    booleanParam(name: 'APPLY', defaultValue: false, description: 'Run terraform apply')
  }
  stages {
    stage('Terraform Init & Plan') {
      steps {
        sh '''
          terraform -version
          terraform init -input=false
          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          terraform plan -input=false -out=plan.out
        '''
      }
    }
    stage('Terraform Apply') {
      when { expression { return params.APPLY } }
      steps {
        sh '''
          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          terraform apply -input=false -auto-approve plan.out
        '''
      }
    }
  }
  post {
    always { archiveArtifacts artifacts: 'plan.out', onlyIfSuccessful: true }
  }
}

