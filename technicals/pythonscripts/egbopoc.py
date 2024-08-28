import subprocess
import sys
import os


def main():
    os.system("git clone https://eceagit:${ECEAGIT_TOKEN}@gerrit.ericsson.se/a/EEA/adp-app-staging")


if __name__ == "__main__":
    main()
