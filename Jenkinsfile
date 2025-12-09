pipeline {
  agent any

  environment {

    REPO = "ghcr.io/ritchie229/argocd-jenkins-k8s-cicd"
    GIT_REPO = "https://github.com/ritchie229/argocd-jenkins-k8s-cicd.git"
    MANIFEST_DIR = "app-manifests"
    IMAGE_TAG = "ver.${env.BUILD_NUMBER}"
    IMAGE_WITH_TAG = "${REPO}:${IMAGE_TAG}"
    GIT_BRANCH = "${env.BRANCH ?: 'main'}"
    GIT_COMMIT = "${env.COMMIT ?: 'HEAD'}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: "${GIT_BRANCH}"]], userRemoteConfigs: [[url: GIT_REPO]]])
        script {
          if (GIT_COMMIT?.trim() && GIT_COMMIT != "HEAD") {
            echo "Checkout commit: ${GIT_COMMIT}"
            sh "git checkout ${GIT_COMMIT}"
          }
        }
      }
    }
    
    stage('Static Analysis: flake8') {
      steps {
        dir('app') {
          sh 'python -m pip install --user pytest flake8'
          sh '~/.local/bin/flake8 . || true' // not failing entire pipeline; change as needed
        }
      }
    }

    stage('Run tests') {
      steps {
        dir('app') {
          sh 'python -m pip install --user -r requirements.txt'
          sh '~/.local/bin/pytest -q'
        }
      }
    }

    stage('Build image') {
      steps {
        dir('app') {
          sh "docker build -t ${IMAGE_WITH_TAG} ."
        }
      }
    }

    stage('Docker login and push') {
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'ghcr-creds', usernameVariable: 'GH_USER', passwordVariable: 'GH_TOKEN')
        ]) {
          sh "echo $GH_TOKEN | docker login ghcr.io -u $GH_USER --password-stdin"
          sh "docker push ${IMAGE_WITH_TAG}"
        }
      }
    }

    stage('Update manifests and git push') {
      steps {
        withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
          sh '''
            git config user.email "jenkins@homelab.com"
            git config user.name "jenkins-ci"
  
            git fetch origin
            git checkout -B ${GIT_BRANCH} origin/${GIT_BRANCH}

            # Меняем всё после ver. на IMAGE_TAG (и для image, и для APP_VERSION)
            sed -i "s|ver\\..*|${IMAGE_TAG}|g" ${MANIFEST_DIR}/deployment.yaml

            cat ${MANIFEST_DIR}/deployment.yaml

            git add ${MANIFEST_DIR}/deployment.yaml
            git commit -m "ci: update image and APP_VERSION to ${IMAGE_TAG} (build ${BUILD_NUMBER}) [ci skip]"

            git remote set-url origin https://${GITHUB_TOKEN}@github.com/ritchie229/argocd-jenkins-k8s-cicd.git
            git push origin ${GIT_BRANCH}
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Build succeeded: ${IMAGE_WITH_TAG}"
    }
    failure {
      echo "Build failed"
    }
  }
}

