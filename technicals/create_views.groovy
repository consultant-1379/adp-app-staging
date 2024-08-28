categorizedJobsView('EEA ADP Staging View') {
    jobs {
        regex(/eea-adp-staging-adp-nx1-loop|eea_adp_staging-seed-job|eea-adp-staging-adp-prepare-baseline|eea-adp-batch-loop|eea-adp-batch-loop-seed-job/)
    }
    categorizationCriteria {
        regexGroupingRule(/seed*/, 'Seed')
        regexGroupingRule(/eea-adp-staging*/, 'EEA ADP Staging')
        regexGroupingRule(/eea-adp-batch-loop/, 'EEA ADP Batch loop')
    }
    columns {
        status()
        weather()
        categorizedJob()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}
categorizedJobsView('EEA Application Staging View') {
    jobs {
        regex(/eea_adp_staging-seed-job|eea-application-staging-baseline-prepare|eea-application-staging-nx1|eea-application-staging-publish-baseline|eea-application-staging-batch|eea-app-baseline-manual-flow-codereview-ok|eea-app-baseline-manual-flow-precodereview|eea-app-baseline-manual-flow-seed-job|eea-application-staging-upgrade|eea-application-staging-product-upgrade/)
    }
    categorizationCriteria {
        regexGroupingRule(/eea-application-staging*/, 'EEA Application Staging')
        regexGroupingRule(/eea-app-baseline-manual-flow*/, 'EEA baseline manual flow')
        regexGroupingRule(/seed*/, 'Seed')
    }
    columns {
        status()
        weather()
        categorizedJob()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}

categorizedJobsView('EEA Product CI Meta-baseline loop View') {
    jobs {
        regex(/eea-product-ci-meta-baseline-loop-manual-job|eea-product-ci-meta-baseline-loop-prepare|eea-product-ci-meta-baseline-loop-test|eea-product-ci-meta-baseline-loop-publish|eea-product-ci-meta-baseline-loop-seed-job|eea-product-ci-meta-baseline-loop-upgrade/)
    }
    categorizationCriteria {
        regexGroupingRule(/eea-product-ci-meta-baseline-loop-manual*/, 'EEA meta baseline manual flow')
        regexGroupingRule(/eea-product-ci-meta-baseline-loop-p*|eea-product-ci-meta-baseline-loop-t*/, 'EEA baseline staging flow')
        regexGroupingRule(/seed*/, 'Seed')
    }
    columns {
        status()
        weather()
        categorizedJob()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}

categorizedJobsView('EEA Product CI Code Loop View') {
    jobs {
        regex(/eea-product-ci-code-loop-prepare|eea-product-ci-code-manual-flow-codereview-ok|eea-product-ci-code-loop-publish|functional-test-loop|eea-product-ci-code-loop-seed-job/)
    }
    categorizationCriteria {
        regexGroupingRule(/eea-product-ci-code-manual*/, 'EEA ci code base manual flow')
        regexGroupingRule(/eea-product-ci-code-loop*/, 'EEA ci code base flow')
        regexGroupingRule(/functional-test-loop*/, 'EEA CI functional test loop')
        regexGroupingRule(/seed*/, 'Seed')
    }
    columns {
        status()
        weather()
        categorizedJob()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}



categorizedJobsView('Technicals View') {
    jobs {
        regex(/dry-runs-job|patchset-verify-jobs|run-hooks-adp-app-staging|run-hooks-cnint|technicals-seed-job|test-seed-job|test-dryrun|verify-hook-job/)
    }
    columns {
        status()
        weather()
        categorizedJob()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}
categorizedJobsView('Technicals_2 View') {
    jobs {
        regex(/dry-runs-job|patchset-verify-jobs|run-hooks-adp-app-staging|run-hooks-cnint|technicals-seed-job|test-dryrun|verify-hook-job/)
    }
    columns {
        status()
        categorizedJob()
        userName()
        workspace()
        lastBuildConsole()
        progressBar()
    }
}
