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
        // we use a second credential for git (personal access token), stored as 'github-token'
        withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
          sh (
            'git config user.email "jenkins@homelab.com" && ' +
            'git config user.name "jenkins-ci" && ' +
          
            'git fetch origin && ' +
            'git checkout -B ' + env.GIT_BRANCH + ' origin/' + env.GIT_BRANCH + ' && ' +
          
            'sed -i \'s|^[[:space:]]*image:.*|  image: ' + env.IMAGE_WITH_TAG + '|\' ' + env.MANIFEST_DIR + '/deployment.yaml && ' +
            'sed -i \'/name: APP_VERSION/{n;s|^[[:space:]]*value:.*|  value: "' + env.IMAGE_TAG + '"|}\' ' + env.MANIFEST_DIR + '/deployment.yaml && ' +

            'cat ' + env.MANIFEST_DIR + '/deployment.yaml && ' +

            'git add ' + env.MANIFEST_DIR + '/deployment.yaml && ' +
            'git commit -m "ci: update image to ' + env.IMAGE_WITH_TAG + ' (build ' + env.BUILD_NUMBER + ') [ci skip]" && ' +

            'git remote set-url origin https://' + env.GITHUB_TOKEN + '@github.com/ritchie229/argocd-jenkins-k8s-cicd.git && ' +
            'git push origin ' + env.GIT_BRANCH
          )
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

