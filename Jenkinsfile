pipeline {
      agent any
      environment {
        //TWISTLOCK_TOKEN = credentials("TWISTLOCK_TOKEN")
        TWISTLOCK_KEY = credentials("TWISTLOCK_KEY")
        TWISTLOCK_SECRET = credentials("TWISTLOCK_SECRET")
        TL_CONSOLE = "https://us-east1.cloud.twistlock.com/us-2-158255088"
       }
        
  stages {
    stage('Clone Github repository') {
      steps {
        checkout scm
      }
    }
    stage('Build Docker Image') {    
      steps {
        script {      
          //app = docker.build("akhng999/vulnerablewebapp:${BRANCH_NAME}") 
          echo "Building Dodcker Image................"
        }
      } 
    }
    stage('Check twistcli version') {
      steps {
        script {
          sh 'chmod a+x ./twistcli'
          def TCLI_VERSION = sh(script: "./twistcli | grep -A1 VERSION | sed 1d", returnStdout:true).trim()
          def CONSOLE_VERSION = sh(script: "curl -k -u \$TWISTLOCK_KEY:\$TWISTLOCK_SECRET $TL_CONSOLE/api/v1/version | tr -d \'\"'", returnStdout:true).trim()
      
          echo "TCLI_VERSION = $TCLI_VERSION"
          echo "CONSOLE_VERSION = $CONSOLE_VERSION"

          if ("$TCLI_VERSION" != "$CONSOLE_VERSION") {
            echo "downloading twistcli"
            sh 'curl -k -u $TWISTLOCK_KEY:$TWISTLOCK_SECRET --output ./twistcli $TL_CONSOLE/api/v1/util/twistcli'
            //sh 'sudo chmod a+x ./twistcli'
          }
        }
      }      
    }
    stage('Scan container before pushing to Dockerhub') {    
      steps {
        script {      
          try {
            sh '''
              ./twistcli images scan \
                --address $TL_CONSOLE \
                --user $TWISTLOCK_KEY \
                --password $TWISTLOCK_SECRET \
                --publish=false \
                --output-file result.json \
                --details \
                akhng999/vulnerablewebapp:${BRANCH_NAME}         
            '''
          } catch (Exception e) {
            echo "Security Test Failed" 
            env.flagError = "true"  
          }
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'result.json', fingerprint: true
        }
      }
    }
    stage('Dockerhub Approval Request') {
      when {
        expression { env.flagError == "true" }
      }
      steps {
        script {
          def userInput = input(id: 'confirm', message: 'This containers contains vulnerabilities. Push to Dockerhub?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Approve Code to Proceed', name: 'approve'] ])
        }
      }
    }   
    stage('Deploy App to Dockerhub') {
      steps {
        script {
          docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
            app.push("latest")
          }
        }
      }              
    }
  }
}
