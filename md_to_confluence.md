# MD conversion to confluence in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Prerequisites

Markdown to confluence generation and upload works with md2cf python project - [Github page](https://github.com/iamjackg/md2cf), [Documentation](https://github.com/iamjackg/md2cf#readme)

This package contains a library part and a script.
Originally, the script is installed and placed on the PATH with name `mdcf`, but **in our pipelines we use a modified version (toctree confluence macro added) of the script**, which can be found and invoked from under `technicals/pythonscripts/markdown_to_confluence.py`.

### Python packages

In order to run technicals/pythonscripts/markdown_to_confluence.py, the python package `md2cf==2.0.1` must be installed on the jenkins build node.

(The package and its dependencies are automatically installed by the jenkins_slave ansible playbook.)

### Confluence technical user

* In order to run `markdown_to_confluence.py`, API token has to be set up which can access the confluence service.
* This is set currently in jenkins credentials in jenkins "seliius27190" as "confluence-api-token"

### Parameters and usage

In our jenkins job the following parameters are used when invoking the script:

Mandatory params:

* `--host`: mandatory, the api url of the confluence server (<https://eteamspace.internal.ericsson.com/rest/api>)
* `--token`: API token for the technical user, mandatory
* `--space`: mandatory, the confluence space where the page will be published (ECISE)
* `filename`: mandatory, the filename or directory to be uploaded

Optional:

* `--parent-title`: parent page, the default value currently set for [**this**](https://eteamspace.internal.ericsson.com/display/ECISE/Auto-generated+documentation+from+adp-app-staging) page in our jenkins job.
* `--preface-markdown`: Here a default preface can be added (eg: *this page is automatically generated, do not edit*!)
* `--debug`: prints traceback at errors

```
python3 adp-app-staging/technicals/pythonscripts/markdown_to_confluence.py \
    --host "${CONFLUENCE_API_URL}" \
    --token "${CONFLUENCE_API_TOKEN}" \
    --parent-title "${CONFLUENCE_ANCESTOR}" \
    --preface-markdown '${confluence_preface}' \
    "${filename}" \
    --debug
```

For all possible parameters of the script, see the documentation or run the script with the `--help` option:

```
markdown_to_confluence.py --help

Usage: md2cf [-h] [-o HOST] [-u USERNAME] [-p PASSWORD] [--token TOKEN] [--insecure] [-s SPACE] [--output {default,minimal,json}] [-a PARENT_TITLE | -A PARENT_ID] [-t TITLE] [-c {page,blogpost}] [-m MESSAGE]
             [--minor-edit] [-i PAGE_ID] [--prefix PREFIX] [--strip-top-header] [--remove-text-newlines] [--replace-all-labels] [--preface-markdown [PREFACE_MARKDOWN] | --preface-file PREFACE_FILE]
             [--postface-markdown [POSTFACE_MARKDOWN] | --postface-file POSTFACE_FILE] [--collapse-single-pages] [--no-gitignore] [--beautify-folders | --use-pages-file] [--collapse-empty | --skip-empty]
             [--enable-relative-links] [--ignore-relative-link-errors] [--dry-run] [--debug] [--only-changed]
             [file_list [file_list ...]]

Positional Arguments:
  file_list             markdown files or directories to upload to Confluence. Empty for stdin

Optional Arguments:
  -h, --help            show this help message and exit
  --dry-run             print information on all the pages instead of uploading to Confluence
  --debug               print full stack traces for exceptions
  --only-changed        only upload pages and attachments that have changed. This adds a hash of the page or attachment contents to the update message

Login Arguments:
  -o, --host HOST       full URL of the Confluence instance. Can also be specified as CONFLUENCE_HOST environment variable.
  -u, --username USERNAME
                        username for logging into Confluence. Can also be specified as CONFLUENCE_USERNAME environment variable.
  -p, --password PASSWORD
                        password for logging into Confluence. Can also be specified as CONFLUENCE_PASSWORD environment variable. If not specified, it will be asked for interactively.
  --token TOKEN         personal access token for logging into Confluence. Can also be specified as CONFLUENCE_TOKEN environment variable.
  --insecure            do not verify SSL certificates

Required Arguments:
  -s, --space SPACE     key for the Confluence space the page will be published to. Can also be specified as CONFLUENCE_SPACE environment variable.

Md2Cf Output Arguments:
  --output {default,minimal,json}

Page Information Arguments:
  -a, --parent-title PARENT_TITLE
                        title of the parent page under which the new page will be uploaded
  -A, --parent-id PARENT_ID
                        ID of the parent page under which the new page will be uploaded
  -t, --title TITLE     a title for the page. Determined from the document if missing
  -c, --content-type {page,blogpost}
                        Content type. Default value: page
  -m, --message MESSAGE
                        update message for the change
  --minor-edit          do not notify watchers of change
  -i, --page-id PAGE_ID
                        ID of the page to be updated
  --prefix PREFIX       a string to prefix to every page title to ensure uniqueness
  --strip-top-header    remove the top level header from the page
  --remove-text-newlines
                        remove single newlines in paragraphs
  --replace-all-labels  replace all labels instead of only adding new ones
  --preface-markdown [PREFACE_MARKDOWN]
                        markdown content to prepend to each page. Defaults to "**Contents are auto-generated, do not edit.**" if no markdown is specified
  --preface-file PREFACE_FILE
                        path to a markdown file to be prepended to every page
  --postface-markdown [POSTFACE_MARKDOWN]
                        markdown content to append to each page. Defaults to "**Contents are auto-generated, do not edit.**" if no markdown is specified
  --postface-file POSTFACE_FILE
                        path to a markdown file to be appended to every page

Directory Arguments:
  --collapse-single-pages
                        if a folder contains a single document, collapse it so the folder doesn't appear
  --no-gitignore        do not use .gitignore files to filter directory search
  --beautify-folders    replace hyphens and underscore in folder names with spaces, and capitalize the first letter
  --use-pages-file      use the "title" entry in YAML files called .pages in each directory to change the folder name
  --collapse-empty      collapse multiple empty folders into one
  --skip-empty          if a folder doesn't contain documents, skip it

Relative Links Arguments:
  --enable-relative-links
                        enable parsing of relative links to other markdown files. Requires two passes for pages with relative links, and will cause them to always be updated regardless of the --only-changed
                        flag
  --ignore-relative-link-errors
                        when relative links are enabled and a link doesn't point to an existing and uploaded file, leave the link as-is instead of exiting.

```

## Jenkins job

* Code is under technicals folder, files created for the process are "md_to_confluence.groovy" and "md_to_confluence.Jenkinsfile"
* Jenkins job is triggered by patchset merge, which contains md file(s)
* The same job can be run **manually** to generate documentation for one gerrit refspec - can be specified in (`GERRIT_REFSPEC`) param, or **all** the .md files (this case `GERRIT_REFSPEC` need to be left empty!)

## Python part

* Python script is under technicals/pythonscripts, the name is markdown_to_confluence.py

## Workflow

* Patchset contains md file merged
* Jenkins job (md-to-confluence) is triggered
* Python script called in the job
* Script converts the markdown to confluence ready format
* Warning message is added to the pages saying it is auto generated
* Page is created/updated in confluence based on the parameters
