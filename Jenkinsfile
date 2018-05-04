pipeline {
  agent any
  stages {
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
        stage('frank') {
          steps {
            sh 'make frank'
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

            // Skipping Acquaint tests because dylib injection with lldb
            // is flakey on the CI machine. We might consider removing
            // these tests instead of porting them when the dylib injection
            // (DYLD_INSERT_LIBRARIES) becomes available.
            // bundle exec bin/test/acquaint.rb
          }
        }
      }
    }
    stage('publish') {
      steps {
        sh 'bin/ci/jenkins/s3-publish.sh release '
      }
    }
  }
  options {
    disableConcurrentBuilds()
    timestamps()
  }
}
