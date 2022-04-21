pipeline {
  agent any
  stages {
    stage('检出') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: [[name: GIT_BUILD_REF]],
          userRemoteConfigs: [[
            url: GIT_REPO_URL,
            credentialsId: CREDENTIALS_ID
          ]]])
        }
      }
      stage('构建镜像并推送到 CODING Docker 制品库') {
        steps {
          script {
            DOCKER_HUB = "https://${CCI_CURRENT_TEAM}-docker.pkg.coding.net"
            IMAGE_NAME = "${PROJECT_NAME.toLowerCase()}/docker/${DEPOT_NAME}"
            docker.withRegistry(
              "${DOCKER_HUB}",
              "${CODING_ARTIFACTS_CREDENTIALS_ID}"
            ) {
              docker.build("${IMAGE_NAME}:${CI_BUILD_ID}", ".").push()
              docker.build("${IMAGE_NAME}:latest", ".").push()
            }
          }

        }
      }
    }
  }