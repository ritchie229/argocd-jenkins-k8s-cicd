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
          sh """
            git config user.email "jenkins@homelab.com"
            git config user.name "jenkins-ci"
            # update deployment.yaml image and APP_VERSION
            # backup original
            # cd ${MANIFEST_DIR}

            git fetch origin
            git checkout -B ${GIT_BRANCH} origin/${GIT_BRANCH}
            # git pull origin ${GIT_BRANCH}

            # Replace image tag line and APP_VERSION env var (works for simple structure)

            # HOME=/tmp yq -i '.spec.template.spec.containers[0].image = "'${IMAGE_WITH_TAG}'"' ${MANIFEST_DIR}/deployment.yaml
            # HOME=/tmp yq -i '.spec.template.spec.containers[0].env[] |= (select(.name=="APP_VERSION") .value = "'${IMAGE_TAG}'")' ${MANIFEST_DIR}/deployment.yaml
            
            # yq -i ".spec.template.spec.containers[0].image = \"${IMAGE_WITH_TAG}\"" ${MANIFEST_DIR}/deployment.yaml
            # yq -i '.spec.template.spec.containers[0].env[] |= (select(.name=="APP_VERSION") .value = strenv(IMAGE_TAG))' ${MANIFEST_DIR}/deployment.yaml
            # sed -i "s|image: .*|image: ${IMAGE_WITH_TAG}|" ${MANIFEST_DIR}/deployment.yaml
            # sed -i "s|name: APP_VERSION.*|$(printf 'name: APP_VERSION\n        value: "%s"' "$IMAGE_TAG")|" ${MANIFEST_DIR}/deployment.yaml


            # Обновляем image
            sed -i "s|^[[:space:]]*image:.*|  image: ${IMAGE_WITH_TAG}|" ${MANIFEST_DIR}/deployment.yaml

            # Обновляем APP_VERSION
            sed -i "/name: APP_VERSION/{n;s|^[[:space:]]*value:.*|  value: \\\\"${IMAGE_TAG}\\\\"|}" ${MANIFEST_DIR}/deployment.yaml

 


            cat ${MANIFEST_DIR}/deployment.yaml

            # Commit & push
            git add ${MANIFEST_DIR}/deployment.yaml
            git commit -m "ci: update image to ${IMAGE_WITH_TAG} (build ${BUILD_NUMBER}) [ci skip]"

            # push via https using token
            git remote set-url origin https://${GITHUB_TOKEN}@github.com/ritchie229/argocd-jenkins-k8s-cicd.git
            git push origin ${GIT_BRANCH}
          """
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

