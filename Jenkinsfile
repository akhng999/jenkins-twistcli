pipeline {
      agent any
      environment {
          // TWISTLOCK_TOKEN = credentials("TWISTLOCK_TOKEN")
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
          app = docker.build("akhng999/vulnerablewebapp:${BRANCH_NAME}") 
        }
      } 
    }
    stage('Scan container before pushing to Dockerhub') {    
      steps {
        script {      
          try {
            sh '''
              docker run \
              -v /var/run/docker.sock:/var/run/docker.sock \
              #-v ${JENKINS_HOME}/jobs/${JOB_NAME%%/*}/branches/${BRANCH_NAME}/builds/${BUILD_NUMBER}/archive:/var/tmp/ \
              -v ${WORKSPACE}:/var/tmp/ \
              --name twistcli-${BUILD_NUMBER} \
              akhng999/twistcli \
              sh -c \
              "./tools/twistcli images scan \
                --address $TL_CONSOLE \
                --user $TWISTLOCK_KEY \
                --password $TWISTLOCK_SECRET \
                --publish=false \
                --output-file /var/tmp/result.json \
                --details \
                akhng999/vulnerablewebapp:${BRANCH_NAME}"     
            '''
          } catch (Exception e) {
            echo "Security Test Failed" 
            env.flagError = "true"  
          }
        }
      }
      post {
        always {
          script {
            sh 'echo "Cleaning up stopped twistcli container....."'
            sh 'docker rm  $(docker ps --filter name=twistcli-${BUILD_NUMBER} -qa)'
            //sh 'sudo chown jenkins:jenkins ${JENKINS_HOME}/jobs/${JOB_NAME%%/*}/branches/${BRANCH_NAME}/builds/${BUILD_NUMBER}/archive/*.json'
          }
          archiveArtifacts artifacts: '**/*.json', fingerprint: true
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
