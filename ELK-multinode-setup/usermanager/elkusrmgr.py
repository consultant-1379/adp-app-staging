#!/usr/bin/env python3

import argparse
import base64
import secrets
import string
import ldap
import smtplib
import time
import yaml
import logging
import logging.config
from pathlib import Path
from email.message import EmailMessage
from pprint import pprint
from elasticsearch import Elasticsearch, NotFoundError


with open(Path(__file__).parent / "config.yaml", 'r') as fd:
    config = yaml.safe_load(fd)

logging.config.dictConfig(config["logger"])
logger = logging.getLogger()
DRY_RUN = False


def get_passwords():
    pwds = {}
    with open(Path(__file__).parent / ".pass", 'r') as fh:
        for line in fh:
            user, pwd = map(base64.b64decode, line.split())
            pwds[user.decode('UTF-8').rstrip()] = pwd.decode('UTF-8').rstrip()
    return pwds


def send_mail(user):
    # Create the base text message.
    msg = EmailMessage()
    msg["Subject"] = "Your Central ELK credentials"
    msg["From"] = "donotreply@ericsson.com"
    msg["To"] = user['mail']
    name = user['givenname'] if user['givenname'] else user['username']
    m = ("Dear {n},\n\n"
         "Your Elasticsearch account credentials have been created:\n"
         "username: {user}\n"
         "password: {pwd}\n\n"
         "Set up the SSH tunnel, and try signing in at:\n"
         "https://seliics00310.ete.ka.sw.ericsson.se:5601/login\n"
         "If you experience any issues, feel free to contact us.\n\n"
         "Best regards,\n"
         "EEA - MS dev").format(n=name, user=user['username'], pwd=user['pw'])
    msg.set_content(m)

    # Send the message
    try:
        with smtplib.SMTP(config["smtp_addr"], config["smtp_port"]) as s:
            # s.set_debuglevel(1)
            s.ehlo()
            # s.starttls()
            s.send_message(msg)
    except Exception as err:
        logger.critical(f"Failed to send email to {user['mail']}.\n{err}")
        return False
    else:
        logger.info(f"Email sent to {user['mail']}")
        return True


def get_pdl_members(ld, pdls):
    members = []

    def expand_distribution_list(members, pdl):
        q = f"(|(mail={pdl}@pdl.internal.ericsson.com)(mailNickname={pdl}))"
        attrlist = ["member"]
        r = ld.search_st('DC=ericsson,DC=se', ldap.SCOPE_SUBTREE, q, attrlist, timeout=9)
        if r and r[0] and r[0][1]:
            for member in r[0][1]['member']:
                m = member.decode('UTF-8').split(',')[0].split('=')[1]
                if m.startswith("PDL"):
                    expand_distribution_list(members, m)
                else:
                    members.append(m.lower())

    for pdl in pdls:
        expand_distribution_list(members, pdl)
    return set(members)


def get_user_info_from_ldap(ld, username, get_all=False):
    """ https://www.python-ldap.org/en/python-ldap-3.3.0/reference/ldap.html """
    uinfo = {}
    q = f"(&(name={username})(objectclass=user))"
    r = ld.search_s('DC=ericsson,DC=se', ldap.SCOPE_SUBTREE, q)
    if r and r[0]:
        if get_all:
            return r[0]
        if r[0][1]:
            backup_mail = r[0][1]['userPrincipalName'][0].decode('UTF-8')
            uinfo['mail'] = r[0][1]['mail'][0].decode('UTF-8') if 'mail' in r[0][1] else backup_mail
            uinfo['givenname'] = r[0][1]['givenName'][0].decode('UTF-8') if 'givenName' in r[0][1] else ''
            uinfo['displayname'] = r[0][1]['displayName'][0].decode('UTF-8') if 'displayName' in r[0][1] else ''
        else:
            logger.warning(f'Incomplete LDAP search result for "{username}":\n{uinfo}')
    else:
        logger.error(f'User "{username}" not found in LDAP')

    return uinfo


def get_ldap_connection(passwords):
    """ https://www.python-ldap.org/en/python-ldap-3.3.0/ """
    try:
        ld = ldap.initialize(config["ldap_addr"], bytes_mode=False)
        ld.set_option(ldap.OPT_PROTOCOL_VERSION, 3)
        ld.set_option(ldap.OPT_REFERRALS, 0)
        ld.set_option(ldap.OPT_NETWORK_TIMEOUT, 10)
        ld.set_option(ldap.OPT_TIMEOUT, 10)
        ld.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)  # TODO
        ld.set_option(ldap.OPT_X_TLS_NEWCTX, 0)
        ld.simple_bind_s(config["ldap_user"].lower() + '@ericsson.se', passwords[config["ldap_user"]])
    except Exception as err:
        logger.critical(f'Could not connect to LDAP!\n{err}')
        raise
    else:
        return ld


def generate_temp_password(length):
    alphabet = string.ascii_letters + string.digits + '!#$%&*+-<=>?@_#'  # + string.punctuation
    password = ''.join(secrets.choice(alphabet) for i in range(length))
    return password


def add_user(es, ld, username, roles):
    """
    https://elasticsearch-py.readthedocs.io/en/7.9.1/xpack.html#elasticsearch.client.security.SecurityClient.put_user
    https://www.elastic.co/guide/en/elasticsearch/reference/7.9/security-api-put-user.html
    """
    elkusers = get_elk_user(es, username)
    if elkusers and username in elkusers:
        logger.debug(f"Skipping already existing user: {username}")
        return

    existing_roles = get_roles(es)
    if not all(role in existing_roles for role in roles):
        logger.error(f"Non existing role in: {roles}")
        return

    uinfo = get_user_info_from_ldap(ld, username)
    if not uinfo:
        return
    if not uinfo['mail'].endswith("ericsson.com"):
        logger.warning(f"Adding non-Ericsson user: {username} ({uinfo['mail']})")

    uinfo['pw'] = generate_temp_password(16)
    uinfo['username'] = username
    body = {
        "password": uinfo['pw'],
        "email": uinfo['mail'],
        "full_name": uinfo['displayname'],
        "roles": roles,
    }

    if DRY_RUN:
        logger.debug(f"DRY RUN: adding user {username} with body: {body}")
        return

    try:
        res = es.security.put_user(username, body)
    except Exception as err:
        logger.critical(f'Could not add user "{username}" to ELK.\n{err}')
    else:
        if 'created' in res and res['created']:
            logger.info(f'User "{username}" creted in ELK.')
            send_mail(uinfo)
        elif 'created' in res and not res['created']:
            logger.info(f'User "{username}" already exists!')
        else:
            logger.error(f'Unknonw error while addig user "{username}" to ELK.\n{res}')


def add_pdl_members(es, ld, pdls):
    logger.debug(f"Creating ELK user for members of {pdls} mailing lists.")
    members = get_pdl_members(ld, pdls)
    for member in members:
        add_user(es, ld, member, config['roles']['default'])
        time.sleep(0.5)


def delete_user(es, username):
    """ https://elasticsearch-py.readthedocs.io/en/7.9.1/xpack.html
        #elasticsearch.client.security.SecurityClient.delete_user """
    if DRY_RUN:
        logger.debug(f"DRY RUN: User {username} deleted!")
        return True

    try:
        res = es.security.delete_user(username)
    except NotFoundError:
        logger.warning(f'Could not delete user "{username}", it does not exist!')
    except Exception as err:
        logger.error(f'Failed to delete user "{username}":\n{err}')
    else:
        if 'found' in res and res['found']:
            logger.info(f'User "{username}" deleted!')
            return True
        else:
            logger.error(f'Unknonw error while deleting user "{username}".\n{res}')
    return False


def get_ldap_user(ld, username):
    pprint(get_user_info_from_ldap(ld, username, get_all=True))


def get_elk_user(es, username=""):
    res = {}
    try:
        res = es.security.get_user(username)
    except NotFoundError:
        pass  # logger.debug(f'Username "{username}" does not exist!')
    except Exception as err:
        logger.error(f'Failed to get user "{username}":\n{err}')

    return res


def get_roles(es):
    res = {}
    try:
        res = es.security.get_role()
    except Exception as err:
        logger.error(f'Failed to get roles:\n{err}')

    return res


def delete_non_pdl_users(es, ld, pdls, sanity=False):
    logger.debug(f"Deleting ELK users who are no longer member of {pdls} mailing lists.")
    pdl_members = get_pdl_members(ld, pdls)
    if not pdl_members:
        logger.error("Failed to get members of PDLs!")
        return
    users = get_elk_user(es)
    # filtering out posibble functional users without email address
    filtered_users = [x for x in users if users[x]['email'] and users[x]['email'].endswith("ericsson.com")]
    for x in config['users_to_keep']:
        if x in filtered_users:
            filtered_users.remove(x)

    users_to_delete = [x for x in filtered_users if x not in pdl_members]
    logger.debug(f"Users to delete: {users_to_delete}")

    if not sanity:
        for user in users_to_delete:
            if delete_user(es, user):
                logger.critical(f'Non PDL member was deleted from ELK: "{user}"!')
    else:
        total = len(users_to_delete)
        for idx, user in enumerate(users_to_delete, start=1):
            print(f"{idx}/{total}")
            pprint(users[user])
            if not input(f'Delete "{user}"? (y/n): ').lower().strip()[:1] == "y":
                continue
            delete_user(es, user)


def get_elasticsearch_api_connection(es_address, es_port, passwords):
    try:
        es = Elasticsearch(
            [f'https://{config["elk_user"]}:{passwords[config["elk_user"]]}@{es_address}:{es_port}'],
            use_ssl=True,
            verify_certs=False,
            ssl_show_warn=False)
    except Exception as err:
        logger.critical(f'Failed to get elk api connection!\n{err}')
        raise
    else:
        return es


def parse_args():
    parser = argparse.ArgumentParser(description="Manage Elasticsearch elements.")
    parser.add_argument("--es-address", dest='es_address', default="seliics00310.ete.ka.sw.ericsson.se")
    parser.add_argument("--es-port", dest='es_port', default="9200")
    parser.add_argument("--roles", help="Add user with these roles")
    parser.add_argument("--dry-run", dest='dry_run', action='store_true', help="Test mode")

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-auto", '--autonomous', action='store_true', help="Add and delete users autonomously")
    group.add_argument("-a", '--add-user', dest="add_users", help="Add user or list of users")
    group.add_argument("-ap", '--add-pdl', dest="add_pdl", help="Add every member from PDL")
    group.add_argument("-d", '--delete-user', dest="del_user", help="Delete a single user")
    group.add_argument("-dnpdl", '--delete-users', dest="del_non_pdl_users", help="Delete users removed from PDL")
    group.add_argument("-g", '--get-elk-user', dest="get_elk_user", help="Print ELK user info")
    group.add_argument("-gr", '--get-roles', dest="get_roles", action='store_true', help="Print ELK roles")
    group.add_argument("-glu", '--get-ldap-user', dest="get_ldap_user", help="Print LDAP user info")
    group.add_argument("-gpdl", '--get-pdl-members', dest="get_pdl", help="Print members of PDL")

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    passwords = get_passwords()
    es = get_elasticsearch_api_connection(args.es_address, args.es_port, passwords)
    ld = get_ldap_connection(passwords)
    if args.dry_run:
        DRY_RUN = args.dry_run
    if DRY_RUN:
        print("DRY RUN IS ON")

    if args.autonomous:
        add_pdl_members(es, ld, config['pdls'])
        delete_non_pdl_users(es, ld, config['pdls'])
    elif args.add_users:
        roles = args.roles.split(',') if args.roles else config['roles']['default']
        for user in args.add_users.split(','):
            add_user(es, ld, user, roles)
    elif args.add_pdl:
        add_pdl_members(es, ld, args.add_pdl.split(','))
    elif args.del_user:
        delete_user(es, args.del_user)
    elif args.del_non_pdl_users:
        delete_non_pdl_users(es, ld, args.del_non_pdl_users.split(','), sanity=True)
    elif args.get_elk_user:
        ret = get_elk_user(es, args.get_elk_user)
        pprint(ret) if ret else print(f'Username "{args.get_elk_user}" does not exist!')
    elif args.get_roles:
        pprint(list(get_roles(es).keys()))
    elif args.get_ldap_user:
        get_ldap_user(ld, args.get_ldap_user)
    elif args.get_pdl:
        members = get_pdl_members(ld, args.get_pdl.split(','))
        for member in members:
            ui = get_user_info_from_ldap(ld, member)
            print('{:<10}{:<30}{:<30}'.format(member, ui['displayname'], ui['mail']))
    else:
        print("Unknown argument, exiting...")
        exit(1)
