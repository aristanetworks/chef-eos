#!/usr/bin/env groovy

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

            sh """
                eval "\$(chef shell-init bash)"
                rake integration_latest
            """"
        }

        stage ('Cleanup') {

            echo 'Cleanup'

            step([$class: 'WarningsPublisher', 
                  canComputeNew: false,
                  canResolveRelativePaths: false,
                  consoleParsers: [[parserName: 'Rubocop'], [parserName: 'Foodcritic']],
                  defaultEncoding: '',
                  excludePattern: '',
                  healthy: '',
                  includePattern: '',
                  unHealthy: ''
            ])

            mail body: 'Chef-eos build successful',
                        from: 'eosplus-dev+jenkins@arista',
                        replyTo: 'eosplus-dev@arista',
                        subject: 'Chef-eos build successful',
                        to: 'jere@arista.com'

        }

    }

    catch (err) {

        currentBuild.result = "FAILURE"

            mail body: "Chef-eos cookbook build error is here: ${env.BUILD_URL}" ,
            from: 'eosplus-dev+jenkins@arista.com',
            replyTo: 'eosplus-dev+jenkins@arista.com',
            subject: 'Chef-eos build failed',
            to: 'jere@arista.com'

            throw err
    }

}

