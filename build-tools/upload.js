const artifact = require('@actions/artifact');
const core = require('@actions/core');
const github = require('@actions/github');

async function uploadArtifact() {
  const artifactClient = artifact.create();
  const artifactName = 'my-artifact';
  const files = [
    '/github/workspace/my-artifact.zip'
  ];
  const rootDirectory = '/github/workspace';
  const options = {
    continueOnError: true
  };

  const uploadResponse = await artifactClient.uploadArtifact(artifactName, files, rootDirectory, options);
  core.info(`Artifact ${artifactName} has been successfully uploaded!`);
}

uploadArtifact().catch(error => core.setFailed(error.message));