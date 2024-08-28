import xml.etree.ElementTree as ET
import glob

allowed = (
    "actions",
    "description",
    "keepDependencies",
    "properties",
    "hudson.model.ParametersDefinitionProperty",
    "hudson.plugins.throttleconcurrents.ThrottleJobProperty",
    "triggers",
    "definition",
    "logRotator",)
allowedParameterTags = (
    "hudson.model.BooleanParameterDefinition",
    "hudson.model.StringParameterDefinition",)
allowedParametersNames = (
    "DRY_RUN",
    "AGENT_LABEL",
    "JENKINSFILE_GERRIT_REFSPEC")
log_element = '"There is a not supported element in the generated job in " + %s + " Element: " + %s'
log_param = '"There is not allowed param in job in" + %s + " Extra param: " + %s + " Allowed params: " + %s'
log_not_allowed_param = '"There is a param which is not allowed in " + %s + " Param: " + %s + " Allowed params: " + %s'
log_property = '"There is a not supported property in the job in " + %s + " Property: " + %s'


def main():
    errorlist = set()
    # ("*[!View].xml") -> exclude every file that is a view
    for file in glob.glob("*[!View].xml"):
        print("Checking", file)
        jenkinsjobconfig = ET.parse(file)

        for child in jenkinsjobconfig.getroot():
            if child.tag not in allowed:
                errorlist.add(log_element % (file, child.tag))

        for elem in jenkinsjobconfig.iter():
            if elem.tag == "properties":
                for job_property in elem:
                    print("Checking properties...")
                    if job_property.tag in allowed:
                        if job_property.tag == "hudson.model.ParametersDefinitionProperty":
                            for parameters in job_property:
                                for parameter in parameters:
                                    print("Checking property...", parameter.tag)
                                    if parameter.tag not in allowedParameterTags:
                                        errorlist.add(log_param % (file, parameter.tag, allowedParameterTags))
                                    for param in parameter:
                                        if param.tag == "name":
                                            if param.text not in allowedParametersNames:
                                                errorlist.add(log_not_allowed_param % (file, param.text, allowedParametersNames))
                    else:
                        errorlist.add(log_property % (file, job_property.tag))
        if errorlist:
            print("List of errors: ", errorlist)
    if not errorlist:
        print("No error")
    else:
        print("exit 1")
        exit(1)


if __name__ == "__main__":
    main()
