# argocd-jenkins-k8s-cicd

Demo project: Flask app + Jenkins CI + ArgoCD CD + GHCR image registry.

## Repo layout
- `app/` — Flask app, Dockerfile, tests, flake8 config
- `app-manifests/` — Kubernetes manifests (kustomize)
- `Jenkinsfile` — Jenkins pipeline: lint, test, build, push, update manifests
- `README.md` — instructions
- `smee.sh` - Webhook Deliveries tool adoption tool https://smee.io/
- `create_repo.sh` - repository creation tool

## Flow
1. Developer pushes code to GitHub.
2. Jenkins pipeline runs tests, static analysis (flake8), builds Docker image and pushes it to GitHub Container Registry (`ghcr.io/ritchie229/argocd-jenkins-k8s-cicd:ver.<BUILD_NUMBER>`).
3. Jenkins updates `app-manifests/deployment.yaml` with the new image tag and pushes the change to GitHub.
4. ArgoCD monitors `app-manifests` and automatically syncs the Kubernetes cluster to the new image tag, hence deploying the app on it.

## Setup (high-level)

### GutHub
1. Create local and remote repository "argocd-jenkins-k8s-cicd"
```bash
./create_repo.sh
```
2. Create all the structire and push to remote
```bash
git add .
git commit -m "Message"
git push
```
### Jenkins
1. Install Jenkins with Docker & Docker Pipeline plugins (Jenkins must be able to run docker), Generic Webhook Trigger Plugin(triggers the job). Also check/install Pipeline, Git plugin, GitHub plugin, Credentials Binding Plugin.
2. Create user token for webhook to use: (User settings→Security→TokenAPI→Add new token→<TOKEN>) and save it in a vault for further usage.
3. Add GitHub credentials in Jenkins: (Settings→Credentials→System→Global credentials→Add credentials→Kind:secret text)
   - `ghcr-creds` (Username with password): username=`ritchie229`, password=`<GHCR_TOKEN>`
   - `github-token` (Secret text): GitHub personal access token with `repo` scope
4. Create a pipeline job pointing to repo; Jenkinsfile is in repo root:
   - New Item → Pipeline → Name: argocd-jenkins-k8s-cicd
   - Generic Webhook Trigger: 
     -- Post content parameters:{'BRANCH:$.ref.split('/')[2]', 'COMMIT:$.after'}
     -- Token: <TOKEN> (see p.3)
     -- Cause: Triggered by GitHub Webhook via smee.io (Optional and random)
   - Pipeline: Pipeline script from SCM:
     -- SCM: Git
     -- Repository URL: https://github.com/ritchie229/argocd-jenkins-k8s-cicd.git
     -- Branch: main (or the branch where the Jenkinsfile is)
     -- Script Path: Jenkinfile (path to the dir where Jenkisfile is, Jenkinsfile can be renamed)

### GitHub Packages (GHCR)
1. Create a GH personal access token with `write:packages` (and `repo` if private).
2. Use that token as `ghcr-creds` in Jenkins.

### ArgoCD
1. Install ArgoCD in the cluster.
2. Create an Application pointing to `app-manifests` path in this repository, target namespace `demo`.
```bash
argocd app create flask-cicd \
  --repo https://github.com/ritchie229/argocd-jenkins-k8s-cicd.git \
  --path app-manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace demo \
  --sync-policy automated \
  --self-heal \
  --auto-prune \
  --sync-option CreateNamespace=true
```
3. Enable automated sync if desired.

### Check if Jenkins can run Docker
```bash
usermod -aG docker jenkins
systemctl restart docker
systemctl restart jenkins
```
```bash
docker build -t ghcr.io/ritchie229/argocd-jenkins-k8s-cicd:ver.test .
echo <GHCR_TOKEN> | docker login ghcr.io -u ritchie229 --password-stdin
docker push ghcr.io/ritchie229/argocd-jenkins-k8s-cicd:ver.test
```

### Kubernetes (imagePull when private)
If images are private, create a docker-registry secret and add `imagePullSecrets` in deployment or set default image pull secret.
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=ritchie229 \
  --docker-password=<GHCR_TOKEN> \
  --docker-email=you@homelab.com \
  -n demo
```

## How Jenkins updates manifest
Jenkins edits `app-manifests/deployment.yaml`, sets:
- `image: ghcr.io/ritchie229/argocd-jenkins-k8s-cicd:ver.<BUILD_NUMBER>`
- env var APP_VERSION = `ver.<BUILD_NUMBER>`
Then commits and pushes the change. ArgoCD picks it up and syncs.

## Optional: SonarQube
- Deploy SonarQube or use hosted service.
- Add `SONAR_TOKEN` to Jenkins and run sonar-scanner during CI.

## Notes / Security
- Do NOT store tokens in repository. Use Jenkins Credentials and k8s secrets.
- For production pipelines consider:
  - using `yq` or `python` to modify YAML instead of naive `sed`.
  - multi-stage Docker builds and smaller base images.
  - signing images or using immutable tags (you already tag with build number).

## Quick local test
1. Build and run locally:
```bash
cd app
docker build -t local-demo:latest .
docker run -p 5000:5000 local-demo:latest
```

## MAKE ALL START AUTOMATIC
### IF ALL ON CLOUD
1. In Jenkins open the job (argocd-jenkins-k8s-cicd) → Configure → Check the box at the bottom **Generic Webhook Trigger** → Save
2. In GitHub repository → Settings → Webhooks → insert URL http://<Jenkins_IP>:8080/generic-webhook-trigger/invoke/ → Type: application/json → Events: Just push events

### IF ALL ON LOCAL
1. Go to https://smee.io and Start a new channel (create tunnel), you will get a smee url containing code → https://smee.io/<CODE>
2. On machine with Jenkins install node.js (check ver. if not less than 18), smee-client.
```bash
node -v
npm -v
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
npm install -g smee-client
```
3. Start proxy to Jenkins
```bash
npx smee \
        -u https://smee.io/<CODE> \
        -t "http://192.168.0.108:8000/generic-webhook-trigger/invoke?token=$TOKEN" \
        -p 8000

```
if success you will see
```nginx
Connected https://smee.io/...
Forwarding to http://192.168.0.108:8080/generic-webhook-trigger/invoke?token=...
```
4. In Github → Repo → Settings → Add webhook
    - Payload URL: https://smee.io/<CODE>
    - Content type: application/json
    - SSL verification: Enable
    - |✔️| Just the push event
    - Add webhook

### USING CLOUDFLARE TUNNEL
1. 



