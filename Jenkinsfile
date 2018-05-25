#!/usr/bin/env groovy

pipeline {
  agent { label 'master' }

  environment {
    SLACK_COLOR_DANGER  = '#E01563'
    SLACK_COLOR_INFO    = '#6ECADC'
    SLACK_COLOR_WARNING = '#FFC300'
    SLACK_COLOR_GOOD    = '#3EB991'
    PROJECT_NAME = 'calabash-ios-server'
  }
  options {
    disableConcurrentBuilds()
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  stages {
    stage('announce') {
      steps {
        slackSend(color: "${env.SLACK_COLOR_INFO}",
            message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Started* (<${env.BUILD_URL}|Open>)")
      }
    }
    stage('build') {
      parallel {
        stage('framework') {
          steps {
            sh 'make framework'
          }
        }
        stage('dylibs') {
          steps {
            sh 'make dylibs'
          }
        }
      }
    }
    stage('prepare') {
      parallel {
        stage('ipa') {
          steps {
            sh 'MAKE_FRAMEWORK=0 make ipa-cal'
          }
        }
        stage('bundle') {
          steps {
            sh 'bundle install'
          }
        }
        stage('appcenter-cli') {
          steps {
            sh 'npm install -g appcenter-cli'
          }
        }
      }
    }
    stage('test') {
      parallel {
        stage('appcenter') {
          steps {
            sh 'bin/ci/jenkins/appcenter.sh'
          }
        }
        stage('local') {
          steps {
            // Starting in Xcode 9, we can run this test headless and
            // in parallel with the other simulator tests - as long as
            // we control the CalabashServer port.  At the moment the
            // the CI machine is running Xcode 8.3.3.
            sh 'bundle exec bin/test/xctest.rb'
            sh 'bundle exec bin/test/cucumber.rb'
          }
        }
      }
    }
    stage('publish') {
      steps {
        sh 'bin/ci/jenkins/s3-publish.sh release'
      }
    }
  }
  post {
    always {
      junit 'cucumber/reports/junit/*.xml'
    }

    aborted {
      echo "Sending 'aborted' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_WARNING}",
               message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Aborted* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }

    failure {
      echo "Sending 'failed' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_DANGER}",
               message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Failed* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }

    success {
      echo "Sending 'success' message to Slack"
      slackSend (color: "${env.SLACK_COLOR_GOOD}",
               message: "${env.PROJECT_NAME} [${env.GIT_BRANCH}] #${env.BUILD_NUMBER} *Success* after ${currentBuild.durationString.replace('and counting', '')}(<${env.BUILD_URL}|Open>)")
    }
  }
}
