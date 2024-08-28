# Send message to Gerrit from a Jenkins pipeline

put these two stages into your pipeline:

```
stage('Prepare') {
    steps {
        dir("adp-app-staging") {
            checkoutGitSubmodules()
        }
    }
}

stage('Send message to Gerrit') {
    steps {
        script {
            env.GERRIT_MSG = 'hello world' // we can supply a custom message here
        }
        dir("adp-app-staging") {
            sh 'bob/bob gerrit-message'
        }
    }
}
```

You may not need the first if you already have that one in your pipeline.
Supply your message in the second stage.
