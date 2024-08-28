# Markdown precodereview

## Jenkins job

Whenever a new patchset - that contains .md files - is uploaded, [markdown-precodereview](https://seliius27190.seli.gic.ericsson.se:8443/job/markdown-precodereview) Jenkins job is started by gerrit trigger.
It runs a markdown linter on the list of the changed .md files of the adp-app-staging repository gerrit refspec. If it finds any errors, logs them in the consol log with the [violated markdown rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) with their line/character numbers. Eg:

```
20:05:53  ./technicals/update_refresh_token.md:10:24 MD034/no-bare-urls Bare URL used [Context: "https://seliius27190.seli.gic...."]
20:05:53  ./technicals/update_refresh_token.md:25:1 MD004/ul-style Unordered list style [Expected: asterisk; Actual: dash]
20:05:53  ./technicals/update_refresh_token.md:25:1 MD007/ul-indent Unordered list indentation [Expected: 2; Actual: 4]
20:05:53  ./technicals/update_refresh_token.md:25:122 MD047/single-trailing-newline Files should end with a single newline character
```

If there are any errors in the markdown files, it gives a **V +1** to the patchset.

## ruleset

The Jenkins job calls the `markdown-lint` rule from `adp-app-staging/ruleset2.0.yaml`
The markdown linter runs from the `bob-docbuilder` image.

```
docker-images:
  (...)
  - doc-builder: armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob-docbuilder:2.10.0-0 --ignore bob/*
  (...)

env:
  (...)
  - MD_FILES

  markdown-lint:
    - task: markdown-lint
      docker-image: doc-builder
      cmd: markdownlint ${env.MD_FILES} --disable MD013 MD024 MD026 MD040
```

### Exceptions

We are currently ignoreing [markdown rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) MD013 MD024 MD026 MD040. This may change in the future - by adding/removing rules in the ruleset command.

## markdownlint implementation

The markdown linter implementation used in bob-docbuilder is [markdownlint](https://github.com/DavidAnson/markdownlint/tree/main), a Node.js stylechecker.

### List of markdown errors

A list of markdown errors that can be raised by the linter and guides on [how to fix them can be found here.](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
