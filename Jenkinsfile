pipeline {
      agent any
      environment {
        //TWISTLOCK_TOKEN = credentials("TWISTLOCK_TOKEN")
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
        // Scan the image
        prismaCloudScanImage ca: '',
        cert: '',
        image: 'akhng999/vulnerablewebapp*',
        key: '',
        logLevel: 'info',
        podmanPath: '',
        project: '',
        resultsFile: 'prisma-cloud-scan-results.json',
        ignoreImageBuildTime:true
      }
      post {
        always {
          //archiveArtifacts artifacts: 'result.json', fingerprint: true
          // The post section lets you run the publish step regardless of the scan results
          prismaCloudPublish resultsFilePattern: 'prisma-cloud-scan-results.json'
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
