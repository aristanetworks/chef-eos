#!/usr/bin/env groovy

/**
 * Jenkinsfile for Chef cookbook for EOS
 * from https://github.com/aristanetworks/chef-arista/edit/develop/Jenkinsfile
 */

node('vagrant') {

    currentBuild.result = "SUCCESS"

    try {

        stage ('Checkout') {

            checkout scm
            sh """
                eval "\$(chef shell-init bash)"
                gem list --local
                gem install foodcritic
                gem install bundler
            """
        }

        stage ('Check_style') {

            try {
                sh """
                    eval "\$(chef shell-init bash)"
                    rake style
                """
            }
            catch (Exception err) {
                currentBuild.result = "UNSTABLE"
            }
            echo "RESULT: ${currentBuild.result}"
        }

        stage ('ChefSpec Unittest') {

            sh """
                eval "\$(chef shell-init bash)"
                echo '--format RspecJunitFormatter' > .rspec
                echo '--out result.xml' >> .rspec
                rake unit
            """

            step([$class: 'JUnitResultArchiver', testResults: 'result.xml'])

        }

        stage ('TestKitchen integration') {

            // wrap([$class: 'AnsiColorSimpleBuildWrapper', colorMapName: "xterm"]) {
                sh """
                    eval "\$(chef shell-init bash)"
                    rake integration_latest
                """
            // }
        }

        stage ('Cleanup') {

            echo 'Cleanup'

            step([$class: 'WarningsPublisher', 
                  canComputeNew: false,
                  canResolveRelativePaths: false,
                  consoleParsers: [
                                   [parserName: 'Rubocop'],
                                   [parserName: 'Foodcritic']
                                  ],
                  defaultEncoding: '',
                  excludePattern: '',
                  healthy: '',
                  includePattern: '',
                  unHealthy: ''
            ])

           mail body: "${env.BUILD_URL} build successful.\n" +
                      "Started by ${env.BUILD_CAUSE}",
                from: 'eosplus-dev+jenkins@arista',
                replyTo: 'eosplus-dev@arista',
                subject: "Chef-eos ${env.JOB_NAME} (${env.BUILD_NUMBER}) build successful",
                to: 'jere@arista.com'

        }

    }

    catch (err) {

        currentBuild.result = "FAILURE"

            mail body: "${env.JOB_NAME} (${env.BUILD_NUMBER}) cookbook build error " +
                       "is here: ${env.BUILD_URL}\nStarted by ${env.BUILD_CAUSE}" ,
                 from: 'eosplus-dev+jenkins@arista.com',
                 replyTo: 'eosplus-dev+jenkins@arista.com',
                 subject: "Chef-eos ${env.JOB_NAME} (${env.BUILD_NUMBER}) build failed",
                 to: 'jere@arista.com'

            throw err
    }

}

