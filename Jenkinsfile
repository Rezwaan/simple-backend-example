properties(
  [parameters(
      [string(
        defaultValue: '', description: 'Please add the image name for the deployment version you need', name: 'IMAGE_TAG', trim: true
      ),booleanParam(
        defaultValue: false, description: 'restart deployment', name: 'RESTART_DEPLOYMENT')
      ]
  )]
)

def app, utils
def imageName = 'gcr.io/pace-configs/logistics-backend'
def deployableBranches = ["staging", "master"]
def channels = ["logistics-deployment"]
def serviceName = 'logistics-backend'

node {
  ansiColor('xterm') {
    stage('Clone repository') {
      deleteDir() // Delete workspace directory for cleanup
      checkout([
        $class: 'GitSCM',
        branches: [[name: BRANCH_NAME]],
        extensions: [[$class: 'CloneOption', noTags: false]],
        userRemoteConfigs: [[credentialsId: 'github-access', url: 'https://github.com/UsePace/logistics-backend.git']]])
      withCredentials([usernamePassword(credentialsId: 'github-access', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
        sh('git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/usepace/devops-works.git devops-works')
      }
      utils = load("./devops-works/jenkins-ci/utils.groovy")
      if(BRANCH_NAME == 'master') { // Bump version if the branch master
        RUN_PIPELINE = utils.bumpVersion() // Run pipeline iff it's a version commit
      } else {
        RUN_PIPELINE = true // if branch isn't deployable, run pipeline as normal
      }
      if (RUN_PIPELINE) {
        utils.setup() // Stop previous builds
      }
    }

    stage('Restart Deployment') {
      if(env.RESTART_DEPLOYMENT == 'true' && BRANCH_NAME in deployableBranches) {
        // Restart deployment with the same image tag
        utils.restartDeploymentKubernetes('logistics-backend-web') // restart deployment logistics-backend-web
        utils.restartDeploymentKubernetes('logistics-backend-worker') // restart deployment logistics-backend-worker
        utils.restartDeploymentKubernetes('logistics-backend-concurrent-worker') // restart deployment logistics-backend-concurrent-worker
        utils.restartDeploymentKubernetes('logistics-backend-assignment') // restart deployment logistics-backend-assignment
        for(int i=0; i < 97; i++){
          utils.restartDeploymentKubernetes("logistics-backend-riders-location-${i}")  // restart deployment logistics-backend-riders-location
        }
      }
    }

    stage('Build image') {
      if(RUN_PIPELINE && !env.IMAGE_TAG && (!env.RESTART_DEPLOYMENT || env.RESTART_DEPLOYMENT == 'false')) {
        // add revision to image
        utils.addRevisionToImage()

        // add secrets
        if (BRANCH_NAME in deployableBranches) sh 'cp infra-config/entry_point_production.sh infra-config/entry_point.sh'
        sh 'cp config/secrets.example.yml config/secrets.yml'

        COMMIT = utils.getCommit()
        utils.dockerRegistry { // build test image with our docker registry credentials
          app = docker.build("$imageName:jenkins-$COMMIT", "--no-cache .") // docker is a jenkins plugin wrapper for docker cli
        }
        utils.pushImage(app, ["jenkins-$COMMIT"]) // Push image for test slaves to pull
      }
    }

    stage('Test image') {
      // Skip unit tests in case the branch is deployable
      if(!env.IMAGE_TAG && (!env.RESTART_DEPLOYMENT || env.RESTART_DEPLOYMENT == 'false')) {
        if(BRANCH_NAME in deployableBranches) {
          println "Skipping unit tests" // Because tests already ran in the branch that was merged
        }
        else {
          utils.preparTest(app, "./infra-config/ci/prep-test-env.sh '$app.id' '$serviceName'") {
            sh 'bundle exec rake db:drop db:create db:migrate'
            sh 'rails test'
          }
        }
      }
    }

    stage('Push image') {
      if (RUN_PIPELINE && !env.IMAGE_TAG && (!env.RESTART_DEPLOYMENT || env.RESTART_DEPLOYMENT == 'false') && BRANCH_NAME in deployableBranches) {
        if (BRANCH_NAME == 'staging') tags = ["$BRANCH_NAME-$BUILD_NUMBER"]
        if (BRANCH_NAME == 'master') tags = ["$BRANCH_NAME-${utils.getVersion()}", "$BRANCH_NAME-$BUILD_NUMBER"]
        utils.pushImage(app, tags)
      }
    }

    stage('Deploy') {
      if (RUN_PIPELINE && (!env.RESTART_DEPLOYMENT || env.RESTART_DEPLOYMENT == 'false') && BRANCH_NAME in deployableBranches) {
        // migrate database
        utils.updateJob('logistics-backend-migration', 'infra-config/k8s/logistics-backend-migration.yaml', env.IMAGE_TAG)

        // Deploy a new image of app
        utils.deployKubernetes('logistics-backend-web', 'logistics-backend-web', imageName, env.IMAGE_TAG) // deploy logistics-backend-web
        utils.deployKubernetes('logistics-backend-worker', 'logistics-backend-worker', imageName, env.IMAGE_TAG) // deploy logistics-backend-worker
        utils.deployKubernetes('logistics-backend-concurrent-worker', 'logistics-backend-concurrent-worker', imageName, env.IMAGE_TAG) // deploy logistics-backend-concurrent-worker
        utils.deployKubernetes('logistics-backend-assignment', 'logistics-backend-assignment', imageName, env.IMAGE_TAG) // deploy logistics-backend-assignment
        for(int i=0; i < 97; i++){
          utils.deployKubernetes("logistics-backend-riders-location-${i}", "logistics-backend-riders-location-${i}", imageName, env.IMAGE_TAG) // deploy logistics-backend-riders-location
        }
        if(BRANCH_NAME == 'master') {
          message = "@channel *<${utils.releaseURL()}|${utils.releaseTag()}>* of *${serviceName}* is deployed:\n${utils.releaseChangelog()}"
          utils.notifySlack(channels, message)
        }
      }
    }
  }
}
