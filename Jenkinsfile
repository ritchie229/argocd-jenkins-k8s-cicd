pipeline {
  agent any

  environment {

    REPO = "ghcr.io/ritchie229/argocd-jenkins-k8s-cicd"
    DH_REPO = "ritchie229/argocd-jenkins-k8s-cicd"
    GIT_REPO = "https://github.com/ritchie229/argocd-jenkins-k8s-cicd.git"
    MANIFEST_DIR = "app-manifests"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    IMAGE_WITH_TAG = "${DH_REPO}:ver.${IMAGE_TAG}"
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
          usernamePassword(credentialsId: 'dh-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')
        ]) {
          sh "echo $DH_TOKEN | docker login -u $DH_USER --password-stdin"
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
            cat ${MANIFEST_DIR}/deployment.yaml
            # заменить только ver.<что-угодно> на ver.${IMAGE_TAG}
            sed -i "s/ver\\.[0-9A-Za-z._-]*/ver.${IMAGE_TAG}/g" ${MANIFEST_DIR}/deployment.yaml
            cat ${MANIFEST_DIR}/deployment.yaml
            git add ${MANIFEST_DIR}/deployment.yaml
            git commit -m "ci: update version to ver.${IMAGE_TAG} (build ${BUILD_NUMBER}) [ci skip]"

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

