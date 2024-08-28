#!/usr/bin/env python3
from test import parse_args
from builder_lib.helm3_client import Helm3Client
from builder_lib.helm_test_runner import HelmTestRunner
from builder_lib.kube_client import KubernetesClient
import inspect

HELM = "/usr/share/helm/3.x/helm"
HELM3 = True
HELM_3_REPOSITORY_CONFIG = '/home/helmuser/.helm/repositories.yaml'
HELM_3_REGISTRY_CONFIG = '/home/helmuser/.helm/registry.json'
HELM_3_REPOSITORY_CACHE = '/home/helmuser/.cache/helm/repository'

args = parse_args()
# Validate some switch combinations
if (
    args.configure_imagepull_secret and
    (
        not args.docker_server or
        not args.docker_username or
        not args.docker_password
    )
   ):
    raise ValueError('With the --configure-imagepull-secret the'
                     ' --docker-server --docker-username'
                     ' --docker-password need to be specified')

helm_client = Helm3Client(args.helm_user,
                          args.helm_token,
                          args.kubernetes_namespace,
                          helm_timeout=args.helm_timeout,
                          helm_value_file=args.helm_value_file,
                          helm_variables=args.helm_variables,
                          skip_helm_wait=args.skip_helm_wait,
                          helm_option=args.helm_option)

kube_client = KubernetesClient(args.kubernetes_namespace,
                               args.kubernetes_admin_conf,
                               args.load_incluster_config,
                               args.kube_exec_timeout,
                               args.skip_ssl_verification)


helm_test_runner_paramaters = {'kube_client': kube_client, 'helm_client': helm_client, 'ignore_cleanup': args.ignore_cleanup, 'ignore_post_cleanup': args.ignore_post_cleanup}

# WA: please remove after bob-py3kubehelmbuilder:1.15.1-9 got merged into cnint/ruleset2.0.yaml
helm_test_runner_sig = inspect.signature(HelmTestRunner)
if helm_test_runner_sig.parameters.get('pvc_deletion_check'):
    helm_test_runner_paramaters['pvc_deletion_check'] = args.pvc_deletion_check
# WA: END

runner = HelmTestRunner(**helm_test_runner_paramaters)

runner.teardown(args.dependency_chart_archive, 'dep-' + args.kubernetes_namespace)
