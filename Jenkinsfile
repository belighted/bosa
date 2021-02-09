import groovy.transform.Field

@Field def app_branch_name           = "master"
@Field def devops_branch_name        = "master"
@Field def project_name              = "bosa"
@Field def nexus_assets_registry_url = "assets.bosa.belighted.com"
@Field def nexus_app_registry_url    = "app.bosa.belighted.com"
@Field def nexus_credentials_id      = "nexus-docker-registry"


podTemplate(
        namespace: "devops-tools",
        containers: [
                containerTemplate(name: 'docker', image: 'docker:dind', ttyEnabled: true, privileged: true)
        ],
        envVars: [
                envVar(key: 'DOCKER_OPTS', value: '-H unix:// -H tcp://0.0.0.0:2375')
        ]

) {

    node(POD_LABEL) {
        stage('Git Clone') {
            dir("app/${project_name}") {
                //checking out the app code
                echo 'Checkout the code..'
                checkout scm
                branch_name = env.BRANCH_NAME
                build_number = env.BUILD_NUMBER
                job_base_name = "${env.JOB_NAME}".split('/').last() // We want to get the name of the branch/tag
                jenkins_server_name = env.BUILD_URL.split('/')[2].split(':')[0]
                echo "Jenkins checkout from branch: $branch_name && $build_number"
                echo "Running job ${job_base_name} on jenkins server ${jenkins_server_name}"
                code_path = pwd()
            }
            dir("devops"){
                git(
                        poll: true,
                        url: 'git@github.com:belighted/bosa-infrastructure-core.git',
                        credentialsId: 'vlad-github',
                        branch: "master"
                )
            }

            container('docker') {
                dir("app/${project_name}"){
                    stage('Build test_runner') {
                        sh "./ops/release/test_runner/build"
                    }
                    stage("Compile assets"){
                        sh "docker run -e RAILS_ENV=production --env-file $PWD/ops/release/test_runner/app_env -v $PWD/public:/app/public bosa-testrunner:latest bundle exec rake assets:clean"
                        sh "docker run -e RAILS_ENV=production --env-file $PWD/ops/release/test_runner/app_env -v $PWD/public:/app/public bosa-testrunner:latest bundle exec rake assets:precompile"
                    }
                    stage("Build&Push images"){
                        switch (job_base_name){
                            case ~/^\d+\.\d+\.\d+$/:
                                withCredentials([usernamePassword(credentialsId: "${nexus_credentials_id}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                                    sh """
                                        docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD base.bosa.belighted.com
                                        docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD assets.bosa.belighted.com
                                        docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD app.bosa.belighted.com
                                        """
                                    sh "TAG=$job_base_name-$build_number $code_path/ops/release/app/build"
                                    sh "TAG=$job_base_name-$build_number $code_path/ops/release/assets/build"
                                }
                                break
                            default:
                                withDockerRegistry([credentialsId: "${nexus_credentials_id}", url: "https://${nexus_app_registry_url}/${project_name}-base/" ]) {
                                    withDockerRegistry([credentialsId: "${nexus_credentials_id}", url: "https://${nexus_app_registry_url}/${project_name}/"]) {
                                        sh "TAG=$job_base_name-$build_number $code_path/ops/release/app/build"
                                    }
                                    withDockerRegistry([credentialsId: "${nexus_credentials_id}", url: "https://${nexus_assets_registry_url}/${project_name}-assets/"]) {
                                        sh "TAG=$job_base_name-$build_number $code_path/ops/release/assets/build"
                                    }
                                }
                                break
                        }
                    }
                    stage("Deploy to K8s"){
                        echo "TBD"
                    }
                }
            }
        }

    }
}