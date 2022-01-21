pipeline {
      agent any
      environment {
          // TWISTLOCK_TOKEN = credentials("TWISTLOCK_TOKEN")
          TWISTLOCK_KEY = credentials("TWISTLOCK_KEY")
          TWISTLOCK_SECRET = credentials("TWISTLOCK_SECRET")
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
          app = docker.build("akhng999/vulnerablewebapp") 
        }
      } 
    }
    stage('Scan container before pushing to Dockerhub') {    
      steps {
        script {      
          try {
            /* checkpoint cloudguard
            sh 'docker save akhng999/vulnerablewebapp -o vwa.tar' 
            sh './shiftleft image-scan -i ./vwa.tar -t 1800'
            */
            sh '''
              docker run \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v ${JENKINS_HOME}/jobs/${JOB_BASE_NAME}/branches/${BRANCH_NAME}/builds/${BUILD_NUMBER}/:/var/tmp/ \
              --name twistcli-${BUILD_NUMBER} \
              akhng999/twistcli \
              sh -c \
              "./tools/twistcli images scan \
                --address https://us-east1.cloud.twistlock.com/us-2-158255088 \
                --user ${TWISTLOCK_KEY} \
                --password ${TWISTLOCK_SECRET} \
                --publish=false \
                --output-file result.json \
                --details \
                akhng999/vulnerablewebapp; cp -p result.json /var/tmp"     
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
