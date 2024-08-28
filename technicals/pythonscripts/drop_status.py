# flake8: noqa

import sys
import subprocess
import argparse
from datetime import datetime
import re


PARSER = argparse.ArgumentParser()
PARSER.add_argument('-a', '--application', help='name of the Spinnaker application')
PARSER.add_argument('-c', '--config', help='configuration file for Spinnaker')
ARGS = PARSER.parse_args()

try:
    APPLICATION = ARGS.application
    CONFIG = ARGS.config

    ERROR = False

    def printing_error(arg):
        global ERROR
        ERROR = True
        print(f"Error: {arg} is missing!")

    if APPLICATION is None:
        printing_error("APPLICATION")

    if CONFIG is None:
        printing_error("CONFIG")

    if ERROR:
        sys.exit(1)


except Exception as err:
    sys.exit(err)


def list_pipeline_ids():
    "List all pipelines for an application."
    return subprocess.getoutput('spin pipelines list --application ' + APPLICATION + ' --config ' + CONFIG + ' | jq -r \'.[] | "\\(.name) \\(.id)"\'')


def get_pipeline_id(pipeline_name):
    "Convert the pipeline name to pipeline id."
    for pipeline in list_pipeline_ids().splitlines():
        elements = pipeline.split()
        name = elements[0]
        pipeline_id = elements[1]
        if name == pipeline_name:
            return pipeline_id


def get_executions(pipeline_id, limit):
    "List all executions for a given pipeline id."
    return subprocess.getoutput('spin pipeline execution list --pipeline-id ' + pipeline_id + ' --limit ' + str(limit) + ' --config ' + CONFIG + '| jq -r \'.[] | "\\(.id) \\(.status) \\(.trigger.properties.CHART_VERSION) \\(.startTime)"\'')


def get_current_version(pipeline_name):
    fs = open(r"cnint/eric-eea-int-helm-chart/Chart.yaml", 'r')
    contents = fs.read()
    fs.close()
    m = re.search(r'name\: ' + pipeline_name + '.*\n.*\n.*version: ([0-9]+\.[0-9]+\.[0-9]+[\+|\-][0-9]*)', contents, re.MULTILINE)
    if m:
        return m[1]
    else:
        return ''


def parse_executions(pipeline_id, limit):
    "Convert the execution list to more consumable format."
    executions = get_executions(pipeline_id, limit)
    retval = []
    for execution in executions.splitlines():
        elements = execution.split()
        exec_id = elements[0]
        exec_status = elements[1]
        exec_version = elements[2]
        if elements[3] != 'null':
            exec_timestamp = int(elements[3]) / 1000
            retval.append([exec_version, exec_status, datetime.utcfromtimestamp(exec_timestamp).strftime('%Y-%m-%d %H:%M:%S'), exec_id])
        else:
            retval.append([exec_version, exec_status, '', exec_id])
    return retval[::-1]  # reverse the array


def failed_count(results, last_version):
    "Count the failures at the latest executions."
    count = 0
    for result in results:
        if result[1] != 'SUCCEEDED':
            if result[1] != 'RUNNING':
                if result[0] != last_version:
                    count += 1
                else:
                    return count
        else:
            return count
    return count


def last_successful_date(results, last_version):
    "Determine last successful version date."
    for result in results:
        if result[0] == last_version:
            return result[2]
    return '-'


def get_drops(limit):
    print('<html><head><title>EEA4 DROP Status</title><meta http-equiv="refresh" content="300" /></head>')
    print('<h3>EEA4 Microservice drop status as of ' + str(datetime.now()) + '</h3>')
    print('<p><small><i>Please note: failures mean changes in those versions did not make it to the master.</i></small></p>')
    for pipeline in list_pipeline_ids().splitlines():
        elements = pipeline.split()
        name = elements[0]
        pipeline_id = elements[1]
        if name.endswith('drop'):
            last_integrated_version = get_current_version(name[0:-5])  # cut the '-drop' from the end of the name
            results = parse_executions(pipeline_id, limit)
            if len(results) > 0:
                print('<details>')
                f_count = failed_count(results, last_integrated_version)
                failed_text = ''
                color = 'green'
                if f_count > 0:
                    failed_text = ' last ' + str(f_count) + ' failed'
                    color = 'mediumseagreen'
                if f_count > 2:
                    color = 'red'
                print('<summary><font color="' + color + '">' + name + ' (chart: ' + last_integrated_version + ' ' + last_successful_date(results, last_integrated_version) + ') ' + failed_text + '</font></summary>')
                print('<p><table cellpadding=10><tr><th>Version</th><th>Status</th><th>Time</th></tr>')
                for result in results[:10]:
                    print('<tr><td><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + result[3] + '?pipeline=' + name + '&stage=0&step=0&details=pipelineConfig">'+result[0]+'</a></td><td>'+result[1]+'</td><td>'+result[2]+'</td></tr>')
                print('</table></p></details>')
    print('</html>')


def main():
    get_drops(50)


if __name__ == "__main__":
    main()
