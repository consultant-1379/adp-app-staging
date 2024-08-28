#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# Open Spofire login page url -> that will be redirected to IAM client login url
# Then we will login to Spotfire using the new LDAP/IAM user.
# This is needed to make sure that new LDAP/IAM user will be created locally in spotfire server also.
# The user should be visible now in ./config.sh list-users -t configtoolpwd command printout.
# e.g. f:6b150b09-5560-40e2-8320-e1e239217310:rvmisi@https://iam.eea.company-domain.com/auth/realms/local-ldap3
# Now we can add Admin role to this user in spotfire CLI.
#

import argparse
import sys
from time import sleep
from pathlib import Path

from selenium import webdriver
# from selenium.webdriver.chrome.service import Service
# from selenium.webdriver.common.by import By
# from selenium.webdriver.support.wait import WebDriverWait
# from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def get_screenshot_file_full_path(directory, file_name):
    return Path(directory, file_name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--username', '-u', required=True)
    parser.add_argument('--password', '-p', required=True)
    parser.add_argument('--url', default='spotfire.eea.company-domain.com')
    parser.add_argument('--port', default='443')
    parser.add_argument('--chromedriver', default='/root/chrome_driver/chromedriver-linux64/chromedriver')
    parser.add_argument('--screenshots_dir', default='/tmp')
    args = parser.parse_args()

    options = webdriver.ChromeOptions()
    options.add_argument('--ignore-ssl-errors=yes')
    options.add_argument('--ignore-certificate-errors')
    options.add_argument('--headless=new')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')

    if sys.version_info >= (3, 7):
        service = webdriver.chrome.service.Service(args.chromedriver)
        driver = webdriver.Chrome(options=options, service=service)
    else:
        driver = webdriver.Chrome(options=options, executable_path=args.chromedriver)

    try:
        wait = WebDriverWait(driver, 10)
        driver.set_window_size(1920, 1080)
        driver.get(f'https://{args.url}:{args.port}/spotfire')
        sleep(5)
        wait.until(EC.title_is('IDENTITY AND ACCESS MANAGEMENT'))  # wait until redirection to IAM page is done
        driver.save_screenshot(get_screenshot_file_full_path(args.screenshots_dir, 'initial_login_page_loaded.png'))
        print('IAM page is loaded')
        print(f'Credentials to be used for login: {args.username}/{args.password}')
        driver.find_element("name", "username").send_keys(args.username)
        driver.find_element("name", "password").send_keys(args.password)
        driver.find_element("name", "login").click()
        print('Provided user/password info and logged in')
        print('Waiting 7 sec for SF page to be loaded')
        sleep(7)
        driver.save_screenshot(get_screenshot_file_full_path(args.screenshots_dir, 'sf_login_ready.png'))
        # page_content = driver.page_source.encode("utf-8")
        # print(repr(page_content))
        print('Validate that I dont see the IAM page, meaning that login to SF was really successful.')
        if (len(driver.find_elements("name", "login"))):
            raise Exception("Login to SF GUI failed, I still see IAM page!")
    except Exception as ex:
        fail_sceenshot_file = get_screenshot_file_full_path(args.screenshots_dir, f"sf_login_failed_{args.username}.png")
        driver.save_screenshot(fail_sceenshot_file)
        raise Exception(f"Booom, failed... check screenshot, {fail_sceenshot_file} file!") from ex
    finally:
        print("Last step: Driver quit!")
        driver.quit()


if __name__ == '__main__':
    main()
