#!/usr/bin/env python
# flake8: noqa
"""
This is a helper script which will be called from the Jenkins job
This script will do the following:
- parse supplied arguments, warn if missing or wrong
- parse specified cluster-config > host_list
- execute remote commands for specified testing tools
Some parameters considered constants are stored as is

New features:
"""

# importing modules from the install script
from tenable.sc import TenableSC  # noqa: F401
from tenable.sc import APIError
import os
import os.path
import sys
import argparse
import time
from datetime import datetime, timedelta

from common.loggering import initialize_logger
from common.remotesession import RemoteSession

# this script parameters
CURRENT_HOUR_MIN = datetime.now().strftime('%Y%m%d%H%M%S')
CURRENT_HOUR_MIN_TS = str(time.time())[:-3]+'111'
PROJ_DIR = os.environ["WORKSPACE"] + '/scripts/aesr/sec_check_eea4' if "WORKSPACE" in os.environ else os.getcwd()
LOG_DIR = PROJ_DIR + '/logs/'
OUTPUT_DIR = PROJ_DIR + '/outputs/'
LOG_FILE_NAME = os.path.join(LOG_DIR, 'log_' + CURRENT_HOUR_MIN + '.txt')

INSTALL_SCRIPT_REL_ROOT_DIR = '../../e2e/install_script/'  # relative path of the install script from current directory
INSTALL_SCRIPT_ABS_ROOT_DIR = os.path.join(PROJ_DIR, INSTALL_SCRIPT_REL_ROOT_DIR)
# CLUSTER_YAML_DIR = INSTALL_SCRIPT_ABS_ROOT_DIR + 'cluster_configs/'
sys.path.append(INSTALL_SCRIPT_ABS_ROOT_DIR)

# from common.environment_parser import EnvironmentProperties
# from common.environment_parser import EnvironmentPropertiesException


# NIKTO_SERVER = "vmx-eea401"
# NIKTO_SERVER_PW = "EvaiKiO1"
# NIKTO_PORTS = "8443"
# NIKTO_PORTS_FILE = PROJ_DIR + '/nikto_ports.txt'
# NMAP_SERVER = NIKTO_SERVER
# NMAP_SERVER_PW = NIKTO_SERVER_PW
# NMAP_PORT_RANGE = "1-65535"
# OTHER_HOSTS = PROJ_DIR + '/hosts.txt'
# TENABLE_ADDRESS = 'tenable-sc.ericsson.se'
# TENABLE_API_USER = 'user-eea4-api'
# TENABLE_API_ACCESS_KEY = 'd2c58ea0d2904126995d7fdab7b6e29c'
# TENABLE_API_SECRET_KEY = '186ff1986cd54eef8a6d95b1670bf3a1'
POLICY_ID = '1000022'  # DUMMY (only does host discovery)


USE_OTHER_HOSTS = 'false'
LOGSTASH_TEMPLATE = PROJ_DIR + '/logstash_TEMPLATE.conf'
LOGSTASH_LOCAL_CONF = PROJ_DIR + '/logstash.conf'
LS_CHANGE_WORDS = ('@CLUSTER_NAME', '@TOOL_NAME', '@SUBSYSTEM', '@TIMESTAMP', '@PACKAGE_VERSION', '@EXECUTION_TIME')
LOGSTASH_LOCATION = "/usr/share/logstash/bin/logstash"
LOGSTASH_CONF = "/tmp/sec_check/logstash.conf"
ELASTIC_SERVER = "selieea0023"
ELASTIC_SERVER_PW = "EvaiKiO1"
ELASTIC_OUTPUT_DIR = "/tmp/sec_check/outputs/"
DOC_ID = ""
SUBSYSTEMS = {"ALL": ["ALL"]}


def str2bool(booleanparse):
    """
    Boolean parser subfunction.
    """
    return booleanparse.lower() in ("yes", "true", "t", "1")


# def get_cluster_yaml(cluster_name):
#    """Returns the cluster YAML name. The naming convention is <cluster_name>_properties.yml"""
#    yaml_file = os.path.join(CLUSTER_YAML_DIR, "{0}_properties.yml".format(cluster_name))
#    if os.path.exists(yaml_file):
#        return yaml_file
#    else:
#        raise IOError(yaml_file + " does not exists!")

def set_elastic_from_cluster_config(cluster):
    global ELASTIC_SERVER
    global USE_OTHER_HOSTS
    print("Elastic is set to {}".format(ELASTIC_SERVER))


def main(argv):
    ''' Main function runs the tool runner functions based on the arguments '''
    ''' usage: nessus.py [-h] -t TARGET -n NAME -v VERSION -arm ARTIFACTORY -at ARMTOKEN [-p POLICY] [-c CONFIGFILE] [-crs CUSTOMREPOSTRUCTURECONFIG] [-o OUTPUTDIR] [-siv SCANINFOVERSION] [-pnum PRODUCTNUMBER] [-pn PRODUCTNAME] [-st TYPE] -sd SERVERDETAILS [-tr TESTRUN] (-tsc | -sat) '''
    cmdparser = argparse.ArgumentParser(description='HC scripts upstream script for Jenkins')
    cmdparser.add_argument('-t', '--target', dest='target', required=True, help="Comma-separated list of target IPs")
    cmdparser.add_argument('-n', '--name', dest='name', required=True, help="SUT name")
    cmdparser.add_argument('-v', '--version', dest='version', required=True, help="SUT version")
    cmdparser.add_argument('-arm', '--artifactory', dest='artifactory', required=True, help="Artfactory Manager Server")
    cmdparser.add_argument('-at', '--armtoken', dest='armtoken', required=True, help="Artfactory Manager Token")
    cmdparser.add_argument('-p', '--policy', dest='policy', required=False, help="Scan Policy, prerequisite on the Tenable.sc")
    cmdparser.add_argument('-c', '--configfile', dest='config', required=False, help="Configuration for nessus.py")
    cmdparser.add_argument('-crs', '--customrepostructureconfig', dest='customrepostructureconfig', required=False, help="Custom repo structure configuration file")
    cmdparser.add_argument('-o', '--outputdir', dest='outputdir', required=False, help="Output Directory for Scanning Results")
    cmdparser.add_argument('-pnum', '--productnumber', dest='productnumber', required=False, help="Number from PRIM structure")
    cmdparser.add_argument('-pn', '--productname', dest='productname', required=False, help="The full product name")
    cmdparser.add_argument('-st', '--type', dest='type', required=False, help="The type of scan, e.g. 'latest' if it's part of a CICD cycle or regular testing or 'customer' if it's not to be considered a development scan such as a scan of an older version.")
    cmdparser.add_argument('-sd', '--serverdetails', dest='serverdetails', required=True, help="Scan server details")
    cmdparser.add_argument('-tr', '--testrun', dest='testrun', required=False, help="Set to True in case of testrun as it will skip uploading the reports to the artifactorys")
    # cmdparser.add_argument('-e', '--elastic', dest='elastic', required=True, help="Set to True for ELK storage")
    # cmdparser.add_argument('-cl', '--cluster', dest='cluster', required=True, help="Specify cluster")
    # cmdparser.add_argument('-ss', '--subsytems', dest='subsystem', required=True, help="ALL")
    args = cmdparser.parse_args(argv)

    # if(args.elastic is None):
    #     args.elastic = 'yes'

    # initialize logs directory
    try:
        logger = initialize_logger(LOG_FILE_NAME)
    except:  # noqa E722
        os.mkdir(LOG_DIR)
        logger = initialize_logger(LOG_FILE_NAME)  # noqa: F841

    # initialize outputs directory
    if not os.path.exists(OUTPUT_DIR):
        os.mkdir(OUTPUT_DIR)
    nessus_run(args)
    print('Logs saved to: ' + LOG_FILE_NAME)


def nessus_run(args):
    ''' Run nessus scan export results and calls the logstash functions '''
    try:
        run_start = int(time.time())
        # exec command
        os.system('python3 /root/adp-test/adp-test-java/src/main/resources/nessus.py -c "/root/adp-test/adp-test-java/src/main/resources/nessus-sc.conf" -t ' + args.target + ' -n ' + args.name + ' -v ' + args.version + ' -p ' + args.policy + ' -o nessus_scan_reports -pn ' + args.productname + ' -pnum ' + args.productnumber + ' -arm arm.rnd.ki.sw.ericsson.se -at dummy -sd /root/adp-test/adp-test-java/templates/tenablesc-secrets-template.yaml -tsc')
        run_end = int(time.time())
        run_time = str(timedelta(seconds=(run_end - run_start)))
        print("Total run time: {}".format(run_time))
        # if re.match('yes', args.elastic):
        #    set_elastic_from_cluster_config(args.cluster)
        #    print("Calling logstash config for nessus_{}".format('ALL'))
        #    logstash_conf_builder(args.cluster, 'nessus_eea4', 'ALL', CURRENT_HOUR_MIN_TS, args.version, run_time)
        #    print("Calling logstash runner for nessus_{}".format('ALL'))
        #    print("output file is {}".format(output_name))
        #    logstash_runner(output_name, LOGSTASH_LOCAL_CONF)
        # else:
        #    print("something went wrong with logstash")
    except KeyError as e:
        print('Invalid credentials or there is already an open session for {}, error {}'.format(TENABLE_USER, str(e)))  # noqa: F821
    finally:
        try:
            print('Logging out, but why')

        except APIError:
            return


def logstash_conf_builder(cluster, tool, subsystem, ts, version, runtime):
    '''Create the logstash.conf from the logstash_TEMPLATE.conf based on the parameters'''
    file_in = LOGSTASH_TEMPLATE
    file_out = LOGSTASH_LOCAL_CONF
    ls_replace_words = (cluster, tool, subsystem, ts, version, runtime)
    global DOC_ID
    # DOC_ID = cluster + '_' + tool + '_' + subsystem + '_' + version + '_' + datetime.utcfromtimestamp(int(ts[:-3])).strftime('%Y%m%d%H%M%S')
    DOC_ID = cluster + '_' + tool + '_' + subsystem + '_' + version + '_' + "11111111"
    with open(file_in, "r") as fin:
        with open(file_out, "w") as fout:
            for line in fin:
                for change, replace in zip(LS_CHANGE_WORDS, ls_replace_words):
                    line = line.replace(change, replace)
                line = line.replace('@DOC_ID', DOC_ID)
                fout.write(line)


def logstash_runner(output_file, logstash_conf):
    '''Load the scan output to the elasticsearch by executing the logstash'''
    try:
        remote_script = RemoteSession(ELASTIC_SERVER, 'root', ELASTIC_SERVER_PW)
        remote_script.connect()
        remote_script.send_command_and_check_exit_code('mkdir -p ' + ELASTIC_OUTPUT_DIR)
        remote_script.close()
    except:  # noqa E722
        print("Outputs folder already exists on elastic server!")
    # Copy the output file and the logstash.conf to the elastic server
    os.system('sshpass -p "<pw redacted>" scp ' + OUTPUT_DIR + output_file + ' root@' + ELASTIC_SERVER + ':' + ELASTIC_OUTPUT_DIR + output_file)
    os.system('sshpass -p "<pw redacted>" scp ' + logstash_conf + ' root@' + ELASTIC_SERVER + ':' + LOGSTASH_CONF)
    # Add an '# EOF' line to the end of the output file for the logstash multiline codec
    remote_script = RemoteSession(ELASTIC_SERVER, 'root', ELASTIC_SERVER_PW)
    remote_script.connect()
    remote_script.send_command_and_check_exit_code('echo "# EOF" >> ' + ELASTIC_OUTPUT_DIR + output_file)
    # Start logstash to load output into elastic
    remote_script.send_command_and_check_exit_code('cat ' + ELASTIC_OUTPUT_DIR + output_file + ' | ' + LOGSTASH_LOCATION + ' -f ' + LOGSTASH_CONF)
    # Clean up the output file from the elastic server - temporarily disabled
    # remote_script.send_command_and_check_exit_code('rm -rf ' + ELASTIC_OUTPUT_DIR + output_file)
    remote_script.close()
    # Ensure user peace of mind ;-)
    print('Security scan output loaded to Elasticsearch (' + ELASTIC_SERVER + ') security_scans as: ' + DOC_ID)


if __name__ == '__main__':
    main(sys.argv[1:])
