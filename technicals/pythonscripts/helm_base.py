
import re
import time
from builder_lib.common_utils import execute_command, get_env_var, log


# pylint: disable=too-many-instance-attributes
class BaseClient:
    path = None

    ##########################################################################
    def __init__(self, username, password, namespace, **kwargs):
        self.namespace = namespace
        self.username = username
        self.password = password
        self.helm_timeout = kwargs.pop('helm_timeout')
        self.helm_value_file = kwargs.pop('helm_value_file')
        self.helm_variables = kwargs.pop('helm_variables')
        self.skip_helm_wait = kwargs.pop('skip_helm_wait')
        self.helm_option = kwargs.pop('helm_option')

    ##########################################################################
    def delete_release(self, release_name):
        raise NotImplementedError

    ##########################################################################
    def install_chart_archive(self, name, chart_archive,
                              helm_vars=None, helm_file=None):
        raise NotImplementedError

    ##########################################################################
    def install_chart_from_repo(self, helm_repo, chart_name,
                                chart_version, release_name):
        raise NotImplementedError

    def wait_for_deployed_release_to_appear(self, expected_release_name):
        raise NotImplementedError

    ##########################################################################
    def upgrade_with_chart_archive(self, baseline_release_name, chart_archive):
        raise NotImplementedError

    ##########################################################################
    def get_authentication_string_and_mask(self):
        if (not self.username) or (not self.password):
            helm_username = get_env_var("HELM_USER")
            helm_token_pass = get_env_var("ARM_API_TOKEN")
        else:
            helm_username = self.username
            helm_token_pass = self.password
        if helm_username and helm_token_pass:
            authstr = (
                f' --username {helm_username} --password {helm_token_pass}')
            markstr = helm_token_pass
        else:
            authstr = ''
            markstr = None
        return authstr, markstr

    ##########################################################################
    def get_chart_name(self, chart_archive):
        # Deduct a "chart_name" for using it as part of a release name.
        # Takes the chart archive and does a 'helm inspect chart' on it
        # takes the value part of the name (after the space) from the line
        # starting with 'name: '
        return list(filter(lambda x: x.startswith('name: '),
                           execute_command(f'{self.path} inspect chart ' +
                                           chart_archive
                                           ).split('\n'))
                    )[0].split(' ')[1]

    ##########################################################################
    def update_command(self, command, custom_helm_vars=None,
                       custom_helm_file=None):
        if custom_helm_file:
            command += f' --values {custom_helm_file}'
        elif self.helm_value_file:
            command += f' --values {self.helm_value_file}'
        if custom_helm_vars:
            command += f' --set {custom_helm_vars}'
        elif self.helm_variables:
            command += f' --set {self.helm_variables}'
        return command

    ##########################################################################
    def cleanup_namespace(self):
        log('Cleaning up namespace, deleting all releases in namespace')
        releases = execute_command(f'{self.path} ls --all '
                                   f'--namespace={self.namespace} -q --date -r')
        for release_name in releases.strip().split('\n'):
            log('Cleaning up helm release: ' + release_name)
            if release_name:
                self.delete_release(release_name)

    ##########################################################################
    def list_releases(self):
        list_command = f'{self.path} ls --all --namespace={self.namespace}'
        execute_command(list_command)

    ##########################################################################
    def release_exist_in_namespace(self):
        list_command = f'{self.path} ls --all --namespace={self.namespace}'
        return bool(execute_command(list_command))

    ##########################################################################
    def get_chart_version(self, chart_name, helm_latest_ver_cmd):
        latest_version_all = execute_command(helm_latest_ver_cmd)
        pattern = re.compile(f"baseline/{chart_name}[ \t]*"
                             r"(?P<semver>\d+[.]\d+[.]\d+([-+][^ \t]+)?)")
        results_list = pattern.findall(latest_version_all)
        if not results_list or len(results_list) != 1:
            raise ValueError(f'{self.path} search found 0 or more than 1 '
                             f'charts:  {results_list}')
        chart_version = results_list[0][0]
        return chart_version

    ##########################################################################
    def upgrade(self, baseline_release_name, chart_archive, release_name):
        if not release_name or release_name != baseline_release_name:
            raise ValueError('Unable to find expected baseline release: ' +
                             baseline_release_name)

        upgrade_command = (f'{self.path} upgrade %s %s --namespace %s --debug '
                           '--timeout %s%s%s%s%s' %
                           (baseline_release_name,
                            chart_archive,
                            self.namespace,
                            (f'{self.helm_timeout}' + 's'),
                            ('' if self.skip_helm_wait else ' --wait'),
                            (' ' + str(' '.join(self.helm_option))
                             if self.helm_option else ''),
                            (' --values ' + self.helm_value_file
                             if self.helm_value_file is not None else ''),
                            (' --set ' + self.helm_variables
                             if self.helm_variables is not None else '')))

        execute_command(upgrade_command)

    ##########################################################################
    def rollback(self, baseline_release_name, revision, release_name):
        if not release_name or release_name != baseline_release_name:
            raise ValueError('Unable to find expected baseline release: ' +
                             baseline_release_name)

        rollback_cmd = (f'{self.path} rollback %s %s --namespace %s --debug '
                        '--timeout %s%s%s' %
                        (baseline_release_name,
                         revision,
                         self.namespace,
                         (f'{self.helm_timeout}' + 's'),
                         ('' if self.skip_helm_wait else ' --wait'),
                         (' ' + str(self.helm_option)
                          if self.helm_option else '')))

        execute_command(rollback_cmd)

    ##########################################################################
    def wait_for_deployment_to_appear(self, expected_release_name, command):
        log(f"Using: {self.path}")
        counter = 10
        while True:
            release_name = execute_command(command).rstrip().split()

            if expected_release_name in release_name:
                return
            log(f'{expected_release_name} not in {str(release_name)}')
            if counter > 0:
                counter = counter - 1
                time.sleep(3)
            else:
                raise ValueError('Timeout waiting for release to reach '
                                 ' deployed state')

    ##########################################################################
    def install(self, command, markstr, helm_vars=None, helm_file=None):
        command = self.update_command(
            command, helm_vars, helm_file)
        return execute_command(command, mark=markstr)
